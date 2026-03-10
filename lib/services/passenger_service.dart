import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/passenger.dart';
import '../repositories/passenger_repository.dart';

class PassengerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PassengerRepository _passengerRepo;

  PassengerService(this._passengerRepo);

  // ===========================================================================
  // CONSULTA E GESTÃO GLOBAL (CRM)
  // ===========================================================================

  Stream<List<Passenger>> getGlobalPassengersStream() {
    return _passengerRepo.getGlobalPassengersStream();
  }

  Future<void> deletePassenger(String passengerId) async {
    return _passengerRepo.deletePassenger(passengerId);
  }

  // ===========================================================================
  // SALVAMENTO E FINANCEIRO
  // ===========================================================================

  /// Quita o valor total da passagem (Dar baixa total)
  Future<void> settleFullPayment({
    required String passengerId,
    required String excursionId,
    required double fullValue,
  }) async {
    debugPrint("💰 SERVICE: Dando baixa total para o passageiro $passengerId");

    final batch = _firestore.batch();
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);

    try {
      final updates = {
        'depositValue': fullValue,
        'isPaid': true,
        'lastUpdate': FieldValue.serverTimestamp(),
      };

      batch.update(masterRef, updates);
      batch.update(vacancyRef, updates);

      // Importante: Como estamos forçando isPaid = true, incrementamos o contador
      // Nota: O ideal é verificar se já não estava pago antes, mas para "dar baixa"
      // assume-se que estava pendente.
      batch.update(excursionRef, {
        'assentosPagos': FieldValue.increment(1),
        'faturamentoAtual': FieldValue.increment(0.0), // O sync global corrigirá depois
      });

      await batch.commit();
      debugPrint("✅ SERVICE: Baixa total realizada com sucesso.");
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (settleFullPayment): $e");
      rethrow;
    }
  }

  Future<void> savePassenger({
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
  }) async {
    debugPrint("💾 SERVICE: Iniciando salvamento de ${passenger.name}");

    try {
      if (excursionId != null && passenger.seatNumber.isNotEmpty) {
        final seatConflict = await _firestore
            .collection('excursoes')
            .doc(excursionId)
            .collection('vagas')
            .where('poltrona', isEqualTo: passenger.seatNumber)
            .get();

        if (seatConflict.docs.isNotEmpty &&
            seatConflict.docs.first.id != passenger.id) {
          throw Exception(
            "A poltrona ${passenger.seatNumber} já está ocupada por outro passageiro.",
          );
        }
      }

      final savedId = await _passengerRepo.savePassenger(passenger);

      if (excursionId != null) {
        final excursionRef = _firestore.collection('excursoes').doc(excursionId);
        final vacancyRef = excursionRef.collection('vagas').doc(savedId);

        final excursionDoc = await excursionRef.get();
        final double totalValue = (excursionDoc.data()?['precoBase'] ?? 0.0).toDouble();
        final bool isFullyPaid = (depositValue ?? 0.0) >= totalValue;

        await _firestore.runTransaction((transaction) async {
          final vacancySnap = await transaction.get(vacancyRef);
          final bool isNewVacancy = !vacancySnap.exists;

          transaction.set(vacancyRef, {
            'id': savedId,
            'poltrona': passenger.seatNumber,
            'depositValue': depositValue ?? 0.0,
            'isPaid': isFullyPaid,
            'statusEmbarque': 'Pendente',
            'lastUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (isNewVacancy) {
            transaction.update(excursionRef, {
              'assentosReservados': FieldValue.increment(1),
              if (isFullyPaid) 'assentosPagos': FieldValue.increment(1),
            });
          }
        });
      }

      debugPrint("✅ SERVICE: Passageiro e Vaga salvos com sucesso.");
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (savePassenger): $e");
      rethrow;
    }
  }

  // ===========================================================================
  // VÍNCULO E OPERAÇÃO
  // ===========================================================================

  Future<void> linkToExcursion({
    required String passengerId,
    required String excursionId,
    required double depositValue,
    required double totalValue,
    required String? seatNumber,
  }) async {
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);
    final bool isFullyPaid = depositValue >= totalValue;

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.set(vacancyRef, {
          'id': passengerId,
          'depositValue': depositValue,
          'isPaid': isFullyPaid,
          'poltrona': seatNumber,
          'dataReserva': FieldValue.serverTimestamp(),
          'statusEmbarque': 'Pendente',
        });
        transaction.update(masterRef, {'excursionId': excursionId});
        transaction.update(excursionRef, {
          'assentosReservados': FieldValue.increment(1),
          if (isFullyPaid) 'assentosPagos': FieldValue.increment(1),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlinkFromExcursion({
    required String passengerId,
    required String excursionId,
  }) async {
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);

    try {
      final vacancyDoc = await vacancyRef.get();
      if (!vacancyDoc.exists) return;

      final bool wasPaid = vacancyDoc.data()?['isPaid'] ?? false;
      final batch = _firestore.batch();
      batch.delete(vacancyRef);
      batch.update(masterRef, {
        'excursionId': '',
        'seatNumber': '',
        'depositValue': 0.0,
        'isPaid': false,
        'statusEmbarque': 'Pendente',
      });
      batch.update(excursionRef, {
        'assentosReservados': FieldValue.increment(-1),
        if (wasPaid) 'assentosPagos': FieldValue.increment(-1),
      });
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Passenger>> watchPassengersForExcursion(String excursionId) {
    return _firestore
        .collection('excursoes')
        .doc(excursionId)
        .collection('vagas')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Passenger> passengers = [];
          for (var doc in snapshot.docs) {
            final mestre = await _passengerRepo.getPassengerById(doc.id);
            if (mestre != null) {
              final docData = doc.data();
              docData.removeWhere((key, value) => value is FieldValue);
              final combinedData = {...mestre.toMap(), ...docData};
              passengers.add(Passenger.fromMap(doc.id, combinedData));
            }
          }
          passengers.sort((a, b) => a.name.compareTo(b.name));
          return passengers;
        });
  }

  Future<void> updateOperationalStatus({
    required String passengerId,
    required String excursionId,
    Map<String, dynamic>? updates,
    bool? justFinishedPaying,
  }) async {
    if (updates == null) return;
    final Map<String, dynamic> firestoreUpdates = Map.from(updates);
    firestoreUpdates['lastUpdate'] = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);

    try {
      batch.update(masterRef, firestoreUpdates);
      batch.update(vacancyRef, firestoreUpdates);

      if (justFinishedPaying == true) {
        batch.update(excursionRef, {'assentosPagos': FieldValue.increment(1)});
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> finalizeTrip(String passengerId) async {
    try {
      await _passengerRepo.updateMasterData(passengerId, {
        'totalViagens': FieldValue.increment(1),
        'excursionId': null,
        'poltrona': null,
        'statusEmbarque': null,
      });
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (finalizeTrip): $e");
    }
  }
}
