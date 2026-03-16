import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../services/passenger_service.dart';
import '../repositories/passenger_repository.dart';
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
    // Uso de microtask para evitar erros de build
    Future.microtask(() => notifyListeners());
  }

  void _clearError() => _errorMessage = null;

  // ===========================================================================
  // CONSULTAS (READ) - Corrigidas para Multi-tenant
  // ===========================================================================

  /// Stream que observa todos os passageiros da empresa (CRM Global)
  /// Linha 33 Corrigida: Agora exige companyId
  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    return _service.getGlobalPassengersStream(companyId);
  }

  /// Stream que observa os passageiros vinculados a uma excursão específica
  /// Linha 37 Corrigida: Agora exige companyId para validação de segurança
  Stream<List<Passenger>> watchPassengers(String excursionId, String companyId) {
    return _service.watchPassengersForExcursion(excursionId, companyId);
  }

  // ===========================================================================
  // OPERAÇÕES OPERACIONAIS (CHECK-IN / FINANCEIRO / VÍNCULO)
  // ===========================================================================

  /// Quita o valor total da passagem baseada no valor de venda congelado
  Future<void> settleFullPayment({
    required BuildContext context,
    required String passengerId,
    required String excursionId,
    required double fullValue,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      await _service.settleFullPayment(
        passengerId: passengerId,
        excursionId: excursionId,
        fullValue: fullValue,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (settleFullPayment): $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza dados operacionais. 
  /// Nota: A quitação (isPaid) agora é validada pelo Service via saleValue.
  Future<void> updateOperationalData({
    required BuildContext context,
    required String excursionId,
    required String passengerId,
    BoardingStatus? status,
    String? seatNumber,
    double? depositValue,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (status != null) updates['statusEmbarque'] = status.value;
      if (seatNumber != null) updates['poltrona'] = seatNumber;
      if (depositValue != null) updates['depositValue'] = depositValue;

      await _service.updateOperationalStatus(
        passengerId: passengerId,
        excursionId: excursionId,
        updates: updates,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (updateOperationalData): $_errorMessage");
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
    _clearError();
    _setLoading(true);
    try {
      await _service.unlinkFromExcursion(
        passengerId: passengerId,
        excursionId: excursionId,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (unlinkPassenger): $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // GESTÃO DE CADASTRO E CRM
  // ===========================================================================

  /// Salva ou Atualiza um passageiro no CRM e, opcionalmente, vincula a uma excursão.
  /// O Service cuidará de congelar o precoBase atual no saleValue.
  Future<bool> savePassenger({
    required BuildContext context,
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      await _service.savePassenger(
        passenger: passenger,
        excursionId: excursionId,
        depositValue: depositValue,
      );

      if (context.mounted && excursionId != null && excursionId.isNotEmpty) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (savePassenger): $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Vincula um passageiro que já existe no CRM a uma nova excursão congelando o preço
  Future<bool> linkExistingPassenger({
    required BuildContext context,
    required String passengerId,
    required String excursionId,
    required double depositValue,
    required double totalValue,
    String? seatNumber,
  }) async {
    _clearError();
    _setLoading(true);
    try {
      await _service.linkToExcursion(
        passengerId: passengerId,
        excursionId: excursionId,
        depositValue: depositValue,
        totalValue: totalValue, // Este valor será o saleValue (preço de venda)
        seatNumber: seatNumber,
      );

      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (linkExistingPassenger): $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove permanentemente o passageiro do CRM Global
  Future<void> deletePassenger(String passengerId) async {
    _clearError();
    _setLoading(true);
    try {
      await _service.deletePassenger(passengerId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("❌ Provider Error (deletePassenger): $_errorMessage");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
