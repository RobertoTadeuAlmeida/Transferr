import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';

class ExcursionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _excursionsRef =>
      _firestore.collection('excursoes');

  CollectionReference<Map<String, dynamic>> _vagasRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('vagas');

  CollectionReference<Map<String, dynamic>> _expensesRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('despesas');

  /// Escuta as excursões filtrando pela EMPRESA (Multi-tenant)
  Stream<List<Excursion>> watchExcursions({String? companyId}) {
    Query<Map<String, dynamic>> query = _excursionsRef;
    if (companyId != null) {
      // Alterado de idResponsavel para empresa para bater com as Security Rules
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

  Future<void> deleteMany(List<String> ids) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      batch.delete(_excursionsRef.doc(id));
    }
    await batch.commit();
  }

  Future<Excursion?> getExcursionById(String excursionId) async {
    try {
      final doc = await _excursionsRef.doc(excursionId).get();
      if (!doc.exists) return null;
      return Excursion.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception("Erro ao buscar excursão: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchVacancies(String excursionId) {
    return _vagasRef(excursionId).snapshots();
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
