import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../services/passenger_service.dart';
import '../repositories/passenger_repository.dart'; // Apenas pro default
import 'excursion_provider.dart';

class PassengerProvider with ChangeNotifier {
  final PassengerService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PassengerProvider({PassengerService? service})
      : _service = service ?? PassengerService(PassengerRepository());

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  // ===========================================================================
  // CONSULTAS (READ)
  // ===========================================================================

  /// Stream que observa todos os passageiros do usuário logado (CRM Global)
  Stream<List<Passenger>> get globalPassengersStream =>
      _service.getGlobalPassengersStream();

  /// Stream que observa os passageiros vinculados a uma excursão específica
  Stream<List<Passenger>> watchPassengers(String excursionId) {
    return _service.watchPassengersForExcursion(excursionId);
  }

  // ===========================================================================
  // OPERAÇÕES OPERACIONAIS (CHECK-IN / FINANCEIRO / VÍNCULO)
  // ===========================================================================

  Future<void> updateOperationalData({
    required BuildContext context,
    required String excursionId,
    required String passengerId,
    BoardingStatus? status,
    String? localAtual,
    String? seatNumber,
    double? depositValue,
    double? totalValue,
    String? agenteId,
  }) async {
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      bool justFinishedPaying = false;

      if (status != null) updates['statusEmbarque'] = status.value;
      if (localAtual != null) updates['localAtual'] = localAtual;
      if (seatNumber != null) updates['poltrona'] = seatNumber; // Ajustado para 'poltrona'

      if (depositValue != null) {
        updates['depositValue'] = depositValue;
        if (totalValue != null && depositValue >= totalValue) {
          justFinishedPaying = true;
          updates['isPaid'] = true;
        } else {
          updates['isPaid'] = false;
        }
      }
      if (agenteId != null) updates['agenteId'] = agenteId;

      await _service.updateOperationalStatus(
        passengerId: passengerId,
        excursionId: excursionId,
        updates: updates,
        justFinishedPaying: justFinishedPaying,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Desvincula o passageiro da excursão (mantendo-o no CRM)
  Future<void> unlinkPassenger({
    required BuildContext context,
    required String passengerId,
    required String excursionId,
  }) async {
    _setLoading(true);
    try {
      await _service.unlinkFromExcursion(
        passengerId: passengerId,
        excursionId: excursionId,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // GESTÃO DE CADASTRO E CRM
  // ===========================================================================

  /// Salva ou Atualiza um passageiro no CRM e, opcionalmente, vincula a uma excursão
  Future<bool> savePassenger({
    required BuildContext context,
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
    double? totalExcursionValue,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // O Service agora cuida de salvar no CRM e criar a vaga se houver excursionId
      await _service.savePassenger(
        passenger: passenger,
        excursionId: excursionId,
        depositValue: depositValue,
      );

      if (context.mounted && excursionId != null && excursionId.isNotEmpty) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ PassengerProvider Error: $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Vincula um passageiro que já existe no CRM a uma nova excursão
  Future<bool> linkExistingPassenger({
    required BuildContext context,
    required String passengerId,
    required String excursionId,
    required double depositValue,
    required double totalValue,
    String? seatNumber,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.linkToExcursion(
        passengerId: passengerId,
        excursionId: excursionId,
        depositValue: depositValue,
        totalValue: totalValue,
        seatNumber: seatNumber,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove permanentemente o passageiro do CRM
  Future<void> deletePassenger(String passengerId) async {
    _setLoading(true);
    try {
      await _service.deletePassenger(passengerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}