import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../services/passenger_service.dart';
import 'excursion_provider.dart';

class PassengerProvider with ChangeNotifier {
  final PassengerService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PassengerProvider(this._service);

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  void _clearError() => _errorMessage = null;

  // REGRA DE NEGÓCIO: Normalização de assento (ex: "05" -> "5")
  String normalizeSeatNumber(String seat) {
    if (seat.isEmpty) return "";
    return int.tryParse(seat)?.toString() ?? seat;
  }

  // REGRA DE NEGÓCIO: Transformar lista em mapa para busca eficiente no grid
  Map<String, Passenger> getSeatMap(List<Passenger> passengers) {
    return {
      for (var p in passengers) normalizeSeatNumber(p.seatNumber): p
    };
  }

  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    return _service.getGlobalPassengersStream(companyId);
  }

  Stream<List<Passenger>> watchPassengers(String excursionId, String companyId) {
    return _service.watchPassengersForExcursion(excursionId, companyId);
  }

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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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
        totalValue: totalValue,
        seatNumber: seatNumber,
      );
      if (context.mounted) {
        await context.read<ExcursionProvider>().syncExcursionStats(excursionId);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePassenger(String passengerId) async {
    _clearError();
    _setLoading(true);
    try {
      await _service.deletePassenger(passengerId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
