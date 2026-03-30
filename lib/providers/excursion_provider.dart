import 'dart:async';
import 'package:flutter/material.dart';
import '../models/excursion.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../services/excursion_service.dart';

class ExcursionProvider with ChangeNotifier {
  final ExcursionService _service;

  List<Excursion> _excursions = [];
  bool _isLoading = false;
  StreamSubscription? _excursionSubscription;
  String? _currentCompanyId;

  List<Excursion> get allExcursions => _excursions;
  bool get isLoading => _isLoading;
  String? get currentCompanyId => _currentCompanyId;

  List<Excursion> get excursions => _excursions.where((e) => !e.isDeleted).toList();
  List<Excursion> get archivedExcursions => _excursions.where((e) => e.isDeleted).toList();
  List<Excursion> get activeExcursions => excursions
      .where((ex) =>
          ex.status == ExcursionStatus.programada ||
          ex.status == ExcursionStatus.emAndamento)
      .toList();

  ExcursionProvider(this._service);

  Excursion? getExcursionById(String id) {
    try {
      return _excursions.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearData() {
    _excursionSubscription?.cancel();
    _excursionSubscription = null;
    _excursions = [];
    _currentCompanyId = null;
    _isLoading = false;
    notifyListeners();
  }

  void listenToExcursions(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      _excursions = [];
      _currentCompanyId = null;
      _excursionSubscription?.cancel();
      _excursionSubscription = null;
      notifyListeners();
      return;
    }

    if (_currentCompanyId == companyId && _excursionSubscription != null) return;

    _currentCompanyId = companyId;
    _setLoading(true);
    _excursionSubscription?.cancel();

    _excursionSubscription = _service.watchExcursions(companyId: companyId).listen(
      (data) {
        _excursions = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _setLoading(false);
      },
    );
  }

  Future<void> startExcursion(String excursionId) async {
    _setLoading(true);
    try {
      await _service.startExcursion(excursionId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finalizeExcursion(String excursionId) async {
    _setLoading(true);
    try {
      await _service.finalizeExcursion(excursionId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelExcursion(String excursionId) async {
    _setLoading(true);
    try {
      await _service.cancelExcursion(excursionId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncExcursionStats(String excursionId) async {
    try {
      await _service.syncExcursionCounters(excursionId);
    } catch (e) {
      debugPrint("❌ Erro ao sincronizar stats: $e");
    }
  }

  Future<Map<String, dynamic>> refreshPassengerPaymentProgress(
    String passengerId,
    String excursionId,
  ) async {
    return await _service.calculatePassengerPaymentProgress(
      passengerId,
      excursionId,
    );
  }

  Future<void> addExcursion(Excursion excursion, String companyId) async {
    // SEGURANÇA: Garante que a empresa está presente e correta
    if (companyId.isEmpty && excursion.empresa.isEmpty) {
      throw Exception("ID da Empresa é obrigatório para criar excursão.");
    }

    _setLoading(true);
    try {
      final String finalCompany = companyId.isNotEmpty 
          ? companyId 
          : excursion.empresa;

      await _service.createExcursion(excursion.copyWith(empresa: finalCompany));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExcursion(Excursion excursion) async {
    _setLoading(true);
    try {
      await _service.updateExcursion(excursion);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMultipleExcursions(List<String> ids) async {
    _setLoading(true);
    try {
      await _service.deleteExcursions(ids);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense({
    required String excursionId,
    required String description,
    required double value,
    required String category,
  }) async {
    // ENDIREITANDO: Adicionado gestão de estado e try-catch
    _setLoading(true);
    try {
      final newExpense = Expense(
        id: '',
        description: description,
        value: value,
        category: category,
        date: DateTime.now(),
      );
      await _service.addExpense(excursionId, newExpense);
    } catch (e) {
      debugPrint("❌ Erro ao adicionar despesa: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    // ENDIREITANDO: Adicionado gestão de estado
    _setLoading(true);
    try {
      await _service.deleteExpense(excursionId, expenseId);
    } catch (e) {
      debugPrint("❌ Erro ao excluir despesa: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<Expense>> watchExpenses(String excursionId) {
    return _service.watchExpenses(excursionId);
  }

  Stream<double> getTotalRevenueStream(String excursionId) {
    return _service.streamTotalRevenue(excursionId);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _excursionSubscription?.cancel();
    super.dispose();
  }
}
