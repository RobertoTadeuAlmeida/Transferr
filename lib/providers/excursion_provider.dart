import 'dart:async';
import 'package:flutter/material.dart';
import '../models/excursion.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../services/excursion_service.dart';
import '../repositories/excursion_repository.dart'; // Mantido temporariamente apenas pro construtor default

class ExcursionProvider with ChangeNotifier {
  final ExcursionService _service;

  // --- ESTADO INTERNO ---
  List<Excursion> _excursions = [];
  bool _isLoading = false;
  StreamSubscription? _excursionSubscription;
  String? _currentUserId;

  // --- GETTERS PÚBLICOS ---
  List<Excursion> get excursions => _excursions;
  bool get isLoading => _isLoading;

  List<Excursion> get activeExcursions => _excursions
      .where((ex) =>
  ex.status == ExcursionStatus.programada ||
      ex.status == ExcursionStatus.emAndamento)
      .toList();

  ExcursionProvider({ExcursionService? service})
      : _service = service ?? ExcursionService(ExcursionRepository());

  // =========================================================================
  // SINCRONIZAÇÃO EM TEMPO REAL
  // =========================================================================

  void listenToExcursions(String? uid) {
    if (uid == null || uid.isEmpty) {
      debugPrint("[ExcursionProvider] 🛑 Logout detectado ou UID vazio.");
      _excursions = [];
      _currentUserId = null;
      _excursionSubscription?.cancel();
      _excursionSubscription = null;
      notifyListeners();
      return;
    }

    if (_currentUserId == uid && _excursionSubscription != null) return;

    debugPrint("[ExcursionProvider] 📡 Iniciando escuta para o usuário: $uid");
    _currentUserId = uid;
    _setLoading(true);
    _excursionSubscription?.cancel();

    _excursionSubscription =
        _service.watchExcursions(responsibleId: uid).listen(
              (data) {
            debugPrint("[ExcursionProvider] ✅ Recebidas ${data.length} excursões do Firebase.");
            _excursions = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("[ExcursionProvider] ❌ Erro na Stream de Excursões: $error");
            _setLoading(false);
          },
        );
  }

  /// Sincroniza os contadores (vagas/pagos).
  /// Este método agora limpa as vagas de outros usuários ou deletadas.
  Future<void> syncExcursionStats(String excursionId) async {
    debugPrint("[ExcursionProvider] 🔄 Solicitando sincronização para: $excursionId");
    try {
      // Chama o service que agora possui a lógica de limpeza de "vagas órfãs"
      await _service.syncExcursionCounters(excursionId);
      debugPrint("[ExcursionProvider] ✨ Sincronização de contadores finalizada.");
    } catch (e) {
      debugPrint("[ExcursionProvider] ❌ Erro ao sincronizar estatísticas: $e");
    }
  }

  // =========================================================================
  // OPERAÇÕES DE EXCURSÃO (CRUD)
  // =========================================================================

  Future<void> addExcursion(Excursion excursion) async {
    _setLoading(true);
    debugPrint("[ExcursionProvider] ➕ Adicionando nova excursão...");
    try {
      final newExcursion = excursion.copyWith(idResponsible: _currentUserId);
      await _service.createExcursion(newExcursion);
      debugPrint("[ExcursionProvider] ✅ Excursão criada com sucesso.");
    } catch (e) {
      debugPrint("[ExcursionProvider] ❌ Erro ao adicionar: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExcursion(Excursion excursion) async {
    debugPrint("[ExcursionProvider] 📝 Atualizando excursão: ${excursion.id}");
    try {
      await _service.updateExcursion(excursion);
      debugPrint("[ExcursionProvider] ✅ Excursão atualizada.");
    } catch (e) {
      debugPrint("[ExcursionProvider] ❌ Erro ao atualizar: $e");
      rethrow;
    }
  }

  Future<void> deleteMultipleExcursions(List<String> ids) async {
    _setLoading(true);
    debugPrint("[ExcursionProvider] 🗑️ Deletando ${ids.length} excursões...");
    try {
      await _service.deleteExcursions(ids);
      debugPrint("[ExcursionProvider] ✅ Exclusão concluída.");
    } catch (e) {
      debugPrint("[ExcursionProvider] ❌ Erro ao deletar: $e");
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
    debugPrint("[ExcursionProvider] 💸 Adicionando despesa de R\$ $value em $excursionId");
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
      debugPrint("[ExcursionProvider] ❌ Erro ao adicionar despesa: $e");
      rethrow;
    }
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    try {
      await _service.deleteExpense(excursionId, expenseId);
    } catch (e) {
      debugPrint("[ExcursionProvider] Erro ao deletar despesa: $e");
      rethrow;
    }
  }

  /// Ouve despesas em tempo real.
  Stream<List<Expense>> watchExpenses(String excursionId) {
    return _service.watchExpenses(excursionId);
  }

  /// Ouve o faturamento total calculado pelo Service.
  Stream<double> getTotalRevenueStream(String excursionId) {
    return _service.streamTotalRevenue(excursionId);
  }

  // =========================================================================
  // MÉTODOS AUXILIARES
  // =========================================================================

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    // Uso do microtask para evitar erros de "setState/markNeedsBuild during build"
    Future.microtask(() => notifyListeners());
  }

  @override
  void dispose() {
    debugPrint("[ExcursionProvider] ⚰️ Dispose chamado.");
    _excursionSubscription?.cancel();
    _currentUserId = null;
    super.dispose();
  }
}