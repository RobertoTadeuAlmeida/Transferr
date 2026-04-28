import 'dart:async';
import '../models/passenger.dart';
import 'package:uuid/uuid.dart';

class DemoPassengerService {
  final _uuid = Uuid();
  final List<Passenger> _passengers = [];
  final StreamController<List<Passenger>> _controller = StreamController.broadcast();

  DemoPassengerService() {
    final now = DateTime.now();
    _passengers.add(Passenger(
      id: 'p1',
      name: 'Passageiro Demo',
      document: '22222222222',
      phone: '977777777',
      company: 'c_demo',
      seatNumber: '',
      saleValue: 0.0,
      createdAt: now,
      lastUpdate: now,
    ));
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(List<Passenger>.from(_passengers));
  }

  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    final stream = _controller.stream.map((list) => list.where((p) => p.company == companyId).toList());
    Future.microtask(_emit);
    return stream;
  }

  Future<void> deletePassenger(String passengerId) async {
    _passengers.removeWhere((p) => p.id == passengerId);
    _emit();
  }

  Future<String> savePassenger(Passenger passenger) async {
    if (passenger.id.isEmpty) {
      final id = _uuid.v4();
      final newP = passenger.copyWith(id: id);
      _passengers.add(newP);
      _emit();
      return id;
    } else {
      final idx = _passengers.indexWhere((p) => p.id == passenger.id);
      if (idx >= 0) {
        _passengers[idx] = passenger;
        _emit();
        return passenger.id;
      } else {
        _passengers.add(passenger);
        _emit();
        return passenger.id;
      }
    }
  }

  // Minimal implementations for methods used by PassengerService
  Future<void> settleFullPaymentBatch({required String passengerId, required String excursionId, required double fullValue}) async {}

  Future<void> runVacancyTransaction({required String excursionId, required String passengerId, required Map<String, dynamic> vacancyData, required bool isNew, required bool wasPaid, required bool isFullyPaid}) async {
    // store a simplified vacancy mapping inside passenger (not persisted)
  }

  Future<void> unlinkFromExcursionBatch({required String passengerId, required String excursionId, required bool wasPaid}) async {
    // no-op demo
  }

  Future<void> updateOperationalBatch({required String passengerId, required String excursionId, required Map<String, dynamic> updates, bool incrementPaidCount = false}) async {}

  Future<Passenger?> getPassengerById(String passengerId, String companyId) async {
    return _passengers.firstWhere((p) => p.id == passengerId && p.company == companyId, orElse: () => null);
  }

  Future<dynamic> getVacancyDoc(String excursionId, String passengerId) async {
    // simple stub
    return {'exists': false};
  }

  Stream<dynamic> watchVacancies(String excursionId) async* {
    // yield empty list wrapper with docs: []
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      yield {'docs': []};
    }
  }

  Future<dynamic> findSeatConflict(String excursionId, String seat) async {
    // return an object with docs list
    return {'docs': []};
  }

  void dispose() {
    _controller.close();
  }
}
