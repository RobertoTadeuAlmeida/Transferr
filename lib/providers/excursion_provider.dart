import 'dart:async'; // Importado para usar o StreamSubscription
import 'package:flutter/material.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/repositories/excursion_repository.dart';

import '../models/participant.dart';

// [MELHORIA] Criei Enums para status. Isso torna o código mais seguro e legível.
// Você precisará ajustar seu modelo `Excursion` e `Participant` para usar estes Enums em vez de `String`.
enum ExcursionStatus { agendada, confirmada, realizada, cancelada }

class ExcursionProvider with ChangeNotifier {
  final ExcursionRepository _repository = ExcursionRepository();
  StreamSubscription? _excursionSubscription; // Para controlar a 'escuta' da stream

  // O estado que a UI irá ouvir
  List<Excursion> _excursions = [];
  bool _isLoading = true; // Inicia como true por padrão

  // --- Getters Públicos ---
  List<Excursion> get excursions => _excursions;
  bool get isLoading => _isLoading;

  // --- Getters Calculados ---
  double get totalGrossRevenue => _excursions.fold(
      0.0, (sum, excursion) => sum + excursion.grossRevenue);

  double get totalNetRevenue =>
      _excursions.fold(0.0, (sum, excursion) => sum + excursion.netRevenue);

  int get totalClientsConfirmed => _excursions.fold(
      0, (sum, excursion) => sum + excursion.totalClientsConfirmed);

  // ------ EXEMPLOS (mantidos da sua versão) ------
  int get totalAvailableSeats {
    const int totalCapacity = 67; // Considere mover isso para uma constante global
    return totalCapacity - totalClientsConfirmed;
  }

  int get totalPayments => _excursions.fold(
      0, (sum, excursion) => sum + (excursion.participants.length));

  int get completePayments {
    int count = 0;
    for (var excursion in _excursions) {
      count += excursion.participants
          .where((p) => p.paymentStatus == PaymentStatus.paid)
          .length;
    }
    return count;
  }

  // --- Construtor ---
  ExcursionProvider() {
    // Inicia ouvindo as mudanças no banco de dados assim que o provider é criado.
    _listenToExcursions();
  }

  /// Inicia a escuta da stream de excursões e lida com dados, erros e finalização.
  void _listenToExcursions() {
    print('[Provider] Iniciando escuta da stream de excursões...');
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _excursionSubscription = _repository.getExcursionsStream().listen(
          (excursionsList) {
        print(
            '[Provider] Dados recebidos da stream! Quantidade: ${excursionsList.length}');
        _excursions = excursionsList;
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners(); // Notifica a UI que a lista foi atualizada!
      },
      onError: (error) {
        print('[Provider] ERRO CRÍTICO na stream: $error');
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners(); // Notifica a UI sobre o erro para parar o loading
      },
      onDone: () {
        print('[Provider] A stream de excursões foi fechada pelo servidor.');
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners();
      },
    );
  }

  // --- Funções CRUD que a UI pode chamar ---

  /// Adiciona uma nova excursão ao Firestore.
  Future<void> addExcursion(Excursion newExcursion) async {
    try {
      await _repository.addExcursion(newExcursion);
      // Não precisa chamar notifyListeners(), pois a Stream já faz isso automaticamente.
    } catch (e) {
      print('Erro ao adicionar excursão: $e');
      rethrow; // Relança o erro para a UI (se ela quiser mostrar um SnackBar, por exemplo)
    }
  }

  /// Atualiza uma excursão existente no Firestore.
  Future<void> updateExcursion(Excursion updatedExcursion) async {
    try {
      await _repository.updateExcursion(updatedExcursion);
    } catch (e) {
      print('Erro ao atualizar excursão: $e');
      rethrow;
    }
  }

  /// Deleta uma excursão do Firestore usando seu ID.
  Future<void> deleteExcursion(Excursion excursionId) async {
    try {
      // [CORREÇÃO] Passando a String 'excursionId' diretamente.
      await _repository.deleteExcursion(excursionId);
    } catch (e) {
      print('Erro ao deletar excursão: $e');
      rethrow;
    }
  }

  // --- Métodos Utilitários ---

  /// Retorna uma cor baseada no status da excursão.
  /// [MELHORIA] Usa o Enum 'ExcursionStatus' em vez de String.
  Color getStatusColor(ExcursionStatus status) {
    switch (status) {
      case ExcursionStatus.agendada:
        return Colors.blueAccent;
      case ExcursionStatus.confirmada:
        return Colors.greenAccent;
      case ExcursionStatus.realizada:
        return Colors.purpleAccent;
      case ExcursionStatus.cancelada:
        return Colors.redAccent;
    }
  }

  /// Busca uma excursão na lista em memória pelo seu ID.
  Excursion? getExcursionById(String excursionId) {
    try {
      return _excursions.firstWhere((excursion) => excursion.id == excursionId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    print('[Provider] Dispose chamado. Cancelando a inscrição da stream.');
    _excursionSubscription?.cancel();
    super.dispose();
  }
}
