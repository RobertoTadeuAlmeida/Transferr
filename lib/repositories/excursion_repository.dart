import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';
import '../models/enums.dart';

class ExcursionRepository {
  final FirebaseFirestore _firestore;

  ExcursionRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _excursionsRef =>
      _firestore.collection('excursoes');

  CollectionReference<Map<String, dynamic>> _vagasRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('vagas');

  CollectionReference<Map<String, dynamic>> _expensesRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('despesas');

  Stream<List<Excursion>> watchExcursions({String? companyId}) {
    Query<Map<String, dynamic>> query = _excursionsRef;
    if (companyId != null) {
      query = query.where('empresa', isEqualTo: companyId);
    }
    return query
        .orderBy('dataPartida', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Excursion.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> add(Excursion excursion) async {
    await _excursionsRef.add(_cleanMap(excursion.toMap()));
  }

  Future<void> update(String excursionId, Map<String, dynamic> data) async {
    await _excursionsRef.doc(excursionId).update(_cleanMap(data));
  }

  /// MARCA como excluído (Soft Delete) em lote por causa das Security Rules
  Future<void> softDeleteMany(List<String> ids) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      batch.update(_excursionsRef.doc(id), {
        'excluido': true,
        'deletadoEm': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<Excursion?> getExcursionById(String excursionId) async {
    final doc = await _excursionsRef.doc(excursionId).get();
    if (!doc.exists) return null;
    return Excursion.fromMap(doc.id, doc.data()!);
  }

  /// Lógica complexa de finalização movida do Service para o Repository
  Future<void> finalizeExcursionBatch({
    required String excursionId,
    required List<Map<String, dynamic>> passengerUpdates,
    required int totalEfetivo,
  }) async {
    final WriteBatch batch = _firestore.batch();
    final excursionRef = _excursionsRef.doc(excursionId);

    for (var update in passengerUpdates) {
      final String passengerId = update['id'];
      final passengerRef = _firestore.collection('passageiros').doc(passengerId);
      
      // Atualiza o mestre do passageiro (CRM)
      batch.update(passengerRef, update['data']);
    }

    // Finaliza a excursão
    batch.update(excursionRef, {
      'status': 'CONCLUIDA',
      'dataFimReal': FieldValue.serverTimestamp(),
      'assentosEfetivos': totalEfetivo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Executa transação financeira de pagamento
  Future<Map<String, dynamic>> runPaymentTransaction({
    required String excursionId,
    required String passengerId,
    required double precoBase,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      final vacancyRef = _vagasRef(excursionId).doc(passengerId);
      final vacancyDoc = await transaction.get(vacancyRef);

      if (!vacancyDoc.exists) throw Exception("Vaga não encontrada.");

      final double valorPago = (vacancyDoc.data()?['depositValue'] ?? 0.0).toDouble();
      final bool estaPago = valorPago >= precoBase;

      transaction.update(vacancyRef, {'isPaid': estaPago});
      
      return {
        'valorPago': valorPago,
        'estaPago': estaPago,
        'percentual': precoBase > 0 ? (valorPago / precoBase).clamp(0.0, 1.0) : 0.0,
      };
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchVacancies(String excursionId) {
    return _vagasRef(excursionId).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getVacancies(String excursionId) {
    return _vagasRef(excursionId).get();
  }

  Stream<List<Expense>> watchExpenses(String excursionId) {
    return _expensesRef(excursionId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addExpense(String excursionId, Expense expense) async {
    await _expensesRef(excursionId).add(_cleanMap(expense.toMap()));
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    await _expensesRef(excursionId).doc(expenseId).delete();
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> data) {
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
