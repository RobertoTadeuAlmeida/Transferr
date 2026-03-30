import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../repositories/passenger_repository.dart';

class PassengerService {
  final PassengerRepository _passengerRepo;

  PassengerService(this._passengerRepo);

  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    return _passengerRepo.getGlobalPassengersStream(companyId);
  }

  Future<void> deletePassenger(String passengerId) async {
    if (passengerId.isEmpty) throw Exception("ID do passageiro inválido.");
    return _passengerRepo.deletePassenger(passengerId);
  }

  Future<void> settleFullPayment({
    required String passengerId,
    required String excursionId,
    required double fullValue,
  }) async {
    if (fullValue < 0) throw Exception("O valor de quitação não pode ser negativo.");
    return _passengerRepo.settleFullPaymentBatch(
      passengerId: passengerId,
      excursionId: excursionId,
      fullValue: fullValue,
    );
  }

  Future<void> savePassenger({
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
  }) async {
    final name = passenger.name.trim();
    if (name.isEmpty) throw Exception("O nome do passageiro é obrigatório.");

    final seat = passenger.seatNumber.trim().toUpperCase();
    final deposit = depositValue ?? 0.0;
    if (deposit < 0) throw Exception("O valor pago não pode ser negativo.");

    if (excursionId != null && excursionId.isNotEmpty) {
      // 1. Validar poltrona
      if (seat.isNotEmpty) {
        final conflict = await _passengerRepo.findSeatConflict(excursionId, seat);
        if (conflict.docs.isNotEmpty && conflict.docs.first.id != passenger.id) {
          throw Exception("A poltrona $seat já está ocupada.");
        }
      }

      // 2. Buscar dados da vaga atual para manter o saleValue (preço congelado)
      final vacancySnap = await _passengerRepo.getVacancyDoc(excursionId, passenger.id);
      final double salePrice = (vacancySnap.data()?['saleValue'] ?? 0.0).toDouble();
      
      // Se for novo e o salePrice for 0, o Service deveria buscar o precoBase da excursão.
      // Simplificando: o Repository/Service garante a integridade.
      
      final bool isFullyPaid = deposit >= salePrice;
      final bool wasPaid = vacancySnap.exists ? (vacancySnap.data()?['isPaid'] ?? false) : false;

      // 3. Salva no CRM
      final savedId = await _passengerRepo.savePassenger(
        passenger.copyWith(name: name, seatNumber: seat, saleValue: salePrice)
      );

      // 4. Executa transação na vaga
      await _passengerRepo.runVacancyTransaction(
        excursionId: excursionId,
        passengerId: savedId,
        isNew: !vacancySnap.exists,
        wasPaid: wasPaid,
        isFullyPaid: isFullyPaid,
        vacancyData: {
          'id': savedId,
          'poltrona': seat,
          'depositValue': deposit,
          'saleValue': salePrice,
          'isPaid': isFullyPaid,
          'statusEmbarque': BoardingStatus.aguardando.value,
          'lastUpdate': FieldValue.serverTimestamp(),
        },
      );
    } else {
      await _passengerRepo.savePassenger(passenger.copyWith(name: name, seatNumber: seat));
    }
  }

  Future<void> linkToExcursion({
    required String passengerId,
    required String excursionId,
    required double depositValue,
    required double totalValue,
    required String? seatNumber,
  }) async {
    final seat = (seatNumber ?? '').trim().toUpperCase();
    final isFullyPaid = depositValue >= totalValue;

    await _passengerRepo.runVacancyTransaction(
      excursionId: excursionId,
      passengerId: passengerId,
      isNew: true,
      wasPaid: false,
      isFullyPaid: isFullyPaid,
      vacancyData: {
        'id': passengerId,
        'depositValue': depositValue,
        'saleValue': totalValue,
        'isPaid': isFullyPaid,
        'poltrona': seat,
        'dataReserva': FieldValue.serverTimestamp(),
        'statusEmbarque': BoardingStatus.aguardando.value,
      },
    );
  }

  Future<void> unlinkFromExcursion({
    required String passengerId,
    required String excursionId,
  }) async {
    final vacancySnap = await _passengerRepo.getVacancyDoc(excursionId, passengerId);
    if (!vacancySnap.exists) return;

    final wasPaid = vacancySnap.data()?['isPaid'] ?? false;

    await _passengerRepo.unlinkFromExcursionBatch(
      passengerId: passengerId,
      excursionId: excursionId,
      wasPaid: wasPaid,
    );
  }

  Stream<List<Passenger>> watchPassengersForExcursion(String excursionId, String companyId) {
    return _passengerRepo.watchVacancies(excursionId).asyncMap((snapshot) async {
      final results = await Future.wait(snapshot.docs.map((doc) async {
        final master = await _passengerRepo.getPassengerById(doc.id, companyId);
        if (master == null) return null;
        
        final docData = doc.data();
        docData.removeWhere((key, value) => value is FieldValue);
        
        return Passenger.fromMap(doc.id, {...master.toMap(), ...docData});
      }));
      
      final passengers = results.whereType<Passenger>().toList();
      passengers.sort((a, b) => a.name.compareTo(b.name));
      return passengers;
    });
  }

  Future<void> updateOperationalStatus({
    required String passengerId,
    required String excursionId,
    Map<String, dynamic>? updates,
  }) async {
    if (updates == null || updates.isEmpty) return;
    
    bool incrementPaidCount = false;

    if (updates.containsKey('depositValue')) {
      final vacancySnap = await _passengerRepo.getVacancyDoc(excursionId, passengerId);
      if (!vacancySnap.exists) throw Exception("Vaga não encontrada.");
      
      final salePrice = (vacancySnap.data()?['saleValue'] ?? 0.0).toDouble();
      final newVal = (updates['depositValue'] as num).toDouble();
      final wasPaid = vacancySnap.data()?['isPaid'] ?? false;

      if (newVal < 0) throw Exception("Valor negativo não permitido.");
      
      if (newVal >= salePrice) {
        updates['isPaid'] = true;
        if (!wasPaid) incrementPaidCount = true;
      } else {
        updates['isPaid'] = false;
      }
    }

    updates['lastUpdate'] = FieldValue.serverTimestamp();

    await _passengerRepo.updateOperationalBatch(
      passengerId: passengerId,
      excursionId: excursionId,
      updates: updates,
      incrementPaidCount: incrementPaidCount,
    );
  }
}
