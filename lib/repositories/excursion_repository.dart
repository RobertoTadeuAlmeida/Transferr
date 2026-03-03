import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';

class ExcursionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- REFERÊNCIAS ---
  CollectionReference<Map<String, dynamic>> get _excursionsRef =>
      _firestore.collection('excursoes');

  CollectionReference<Map<String, dynamic>> _vagasRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('vagas');

  CollectionReference<Map<String, dynamic>> _expensesRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('despesas');

  // =========================================================================
  // 1. MÉTODOS DE EXCURSÃO (DOCUMENTO PAI)
  // =========================================================================

  /// Ouve o stream de excursões, com filtro opcional por responsável.
  Stream<List<Excursion>> watchExcursions({String? responsibleId}) {
    Query<Map<String, dynamic>> query = _excursionsRef;
    if (responsibleId != null) {
      query = query.where('idResponsavel', isEqualTo: responsibleId);
    }
    return query
        .orderBy('dataPartida', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Excursion.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Adiciona um novo documento de excursão.
  Future<void> add(Excursion excursion) async {
    await _excursionsRef.add(_cleanMap(excursion.toMap()));
  }

  /// Atualiza dados no documento de uma excursão.
  Future<void> update(String excursionId, Map<String, dynamic> data) async {
    await _excursionsRef.doc(excursionId).update(_cleanMap(data));
  }

  /// Deleta múltiplos documentos de excursão em um lote.
  Future<void> deleteMany(List<String> ids) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      batch.delete(_excursionsRef.doc(id));
    }
    await batch.commit();
  }

  // =========================================================================
  // 2. MÉTODOS DE VAGAS (SUB-COLEÇÃO)
  // =========================================================================

  /// Ouve a sub-coleção de vagas de uma excursão.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchVacancies(String excursionId) {
    return _vagasRef(excursionId).snapshots();
  }

  // =========================================================================
  // 3. MÉTODOS DE DESPESAS (SUB-COLEÇÃO)
  // =========================================================================

  /// Ouve a sub-coleção de despesas de uma excursão.
  Stream<List<Expense>> watchExpenses(String excursionId) {
    return _expensesRef(excursionId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList());
  }

  /// Adiciona uma nova despesa a uma excursão.
  Future<void> addExpense(String excursionId, Expense expense) async {
    await _expensesRef(excursionId).add(_cleanMap(expense.toMap()));
  }

  /// Deleta uma despesa de uma excursão.
  Future<void> deleteExpense(String excursionId, String expenseId) async {
    await _expensesRef(excursionId).doc(expenseId).delete();
  }

  // =========================================================================
  // 4. UTILITÁRIO
  // =========================================================================

  /// Remove chaves com valores nulos de um mapa para evitar erros no Firestore.
  Map<String, dynamic> _cleanMap(Map<String, dynamic> data) {
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
