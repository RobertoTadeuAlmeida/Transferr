import 'dart:async';
import 'package:flutter/material.dart';
import '../models/excursion.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../services/excursion_service.dart';
import '../repositories/excursion_repository.dart';
import '../repositories/passenger_repository.dart';

class ExcursionProvider with ChangeNotifier {
  final ExcursionService _service;

  // --- ESTADO INTERNO ---
  List<Excursion> _excursions = [];
  bool _isLoading = false;
  StreamSubscription? _excursionSubscription;
  String? _currentCompanyId; // Alterado de currentUserId para currentCompanyId

  // --- GETTERS PÚBLICOS ---
  List<Excursion> get allExcursions => _excursions;
  bool get isLoading => _isLoading;

  List<Excursion> get excursions => _excursions.where((e) => !e.isDeleted).toList();

  List<Excursion> get archivedExcursions => _excursions.where((e) => e.isDeleted).toList();

  List<Excursion> get activeExcursions => excursions
      .where((ex) =>
          ex.status == ExcursionStatus.programada ||
          ex.status == ExcursionStatus.emAndamento)
      .toList();

  ExcursionProvider({ExcursionService? service})
      : _service = service ??
            ExcursionService(ExcursionRepository(), PassengerRepository());

  // =========================================================================
  // SINCRONIZAÇÃO EM TEMPO REAL
  // =========================================================================

  /// Escuta as excursões pela Empresa (companyId) para bater com as Security Rules
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

    // Chamada alterada para usar companyId
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
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finalizeExcursion(String excursionId) async {
    _setLoading(true);
    try {
      await _service.finalizeExcursion(excursionId);
    } catch (e) {
      rethrow;
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

  // =========================================================================
  // OPERAÇÕES DE EXCURSÃO (CRUD)
  // =========================================================================

  Future<void> addExcursion(Excursion excursion) async {
    _setLoading(true);
    try {
      // Importante: Ao criar, vinculamos à empresa atual
      final newExcursion = excursion.copyWith(empresa: _currentCompanyId); 
      await _service.createExcursion(newExcursion);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExcursion(Excursion excursion) async {
    try {
      await _service.updateExcursion(excursion);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMultipleExcursions(List<String> ids) async {
    _setLoading(true);
    try {
      await _service.deleteExcursions(ids);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================================
  // GESTÃO FINANCEIRA
  // =========================================================================

  Future<void> addExpense({
    required String excursionId,
    required String description,
    required double value,
    required String category,
  }) async {
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
      rethrow;
    }
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    try {
      await _service.deleteExpense(excursionId, expenseId);
    } catch (e) {
      rethrow;
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
    Future.microtask(() => notifyListeners());
  }

  @override
  void dispose() {
    _excursionSubscription?.cancel();
    _currentCompanyId = null;
    super.dispose();
  }
}
