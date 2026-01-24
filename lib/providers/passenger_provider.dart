import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../repositories/passenger_repository.dart';

class PassengerProvider with ChangeNotifier {
  final PassengerRepository _repository = PassengerRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Busca global de passageiros (Future)
  /// Usado na tela mestre de passageiros (independente de excursão)
  Future<List<Passenger>> getAllPassengers() async {
    _setLoading(true);
    try {
      return await _repository.getAllPassengers();
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Busca passageiros vinculados a uma excursão específica (Future)
  Future<List<Passenger>> getPassengers(String excursionId) async {
    _setLoading(true);
    try {
      return await _repository.getPassengers(excursionId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Monitora passageiros de uma excursão em tempo real (Stream)
  Stream<List<Passenger>> watchPassengers(String excursionId) {
    return _repository.getPassengersStream(excursionId);
  }

  /// SALVAMENTO COM REGRA DE NEGÓCIO:
  /// 1. Salva o cadastro básico do passageiro.
  /// 2. Se um [excursionId] for fornecido, tenta vincular exigindo o [depositValue].
  Future<bool> savePassenger({
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Etapa 1: Salva o cadastro básico (Base Mestre)
      final String passengerId = await _repository.savePassenger(passenger);

      // Etapa 2: Se houver intenção de vincular a uma excursão
      if (excursionId != null && excursionId.isNotEmpty) {
        if (depositValue == null || depositValue <= 0) {
          throw Exception("O pagamento do sinal é obrigatório para cadastrar na excursão.");
        }

        await _repository.linkToExcursion(
          passengerId: passengerId,
          excursionId: excursionId,
          depositValue: depositValue,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('permission-denied')
          ? 'Erro de permissão no servidor.'
          : e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Método dedicado apenas para vincular passageiros já existentes a novas excursões
  Future<bool> linkExistingPassenger({
    required String passengerId,
    required String excursionId,
    required double depositValue,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _repository.linkToExcursion(
        passengerId: passengerId,
        excursionId: excursionId,
        depositValue: depositValue,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza o assento (String? suporta letras e números)
  Future<void> updatePassengerSeat(String passengerId, String? newSeat) async {
    _setLoading(true);
    try {
      await _repository.updatePassengerSeat(passengerId, newSeat);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBoardingStatus({
    required String passengerId,
    required BoardingStatus status,
    required String agenteId,
  }) async {
    try {
      await _repository.updateBoardingStatus(
        passengerId: passengerId,
        statusValue: status.value,
        agenteId: agenteId,
      );
    } catch (e) {
      debugPrint('Erro no check-in: $e');
      rethrow;
    }
  }

  Future<void> deletePassenger(String passengerId) async {
    _setLoading(true);
    try {
      await _repository.deletePassenger(passengerId);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}