import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
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
    if (passengerId.isEmpty) throw Exception("ID do passageiro inválido.");
    return _passengerRepo.deletePassenger(passengerId);
  }

  // ===========================================================================
  // SALVAMENTO E FINANCEIRO
  // ===========================================================================

  Future<void> settleFullPayment({
    required String passengerId,
    required String excursionId,
    required double fullValue,
  }) async {
    if (fullValue < 0) throw Exception("O valor de quitação não pode ser negativo.");

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

      batch.update(excursionRef, {
        'assentosPagos': FieldValue.increment(1),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      await batch.commit();
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
    final sanitizedName = passenger.name.trim();
    final sanitizedSeat = passenger.seatNumber.trim().toUpperCase();

    if (sanitizedName.isEmpty) throw Exception("O nome do passageiro é obrigatório.");

    try {
      if (excursionId != null && excursionId.isNotEmpty) {
        final excursionRef = _firestore.collection('excursoes').doc(excursionId);
        final excursionDoc = await excursionRef.get();
        
        if (!excursionDoc.exists) throw Exception("Excursão não encontrada.");
        
        final double basePrice = (excursionDoc.data()?['precoBase'] ?? 0.0).toDouble();
        final double finalDeposit = depositValue ?? 0.0;
        
        if (finalDeposit < 0) throw Exception("O valor pago não pode ser negativo.");
        
        // Travamento redundante de segurança
        final double validDeposit = finalDeposit > basePrice ? basePrice : finalDeposit;
        final bool isFullyPaid = validDeposit >= basePrice;

        // Validação de Poltrona (Evitar duplicidade)
        if (sanitizedSeat.isNotEmpty) {
          final seatConflict = await excursionRef
              .collection('vagas')
              .where('poltrona', isEqualTo: sanitizedSeat)
              .get();

          if (seatConflict.docs.isNotEmpty && seatConflict.docs.first.id != passenger.id) {
            throw Exception("A poltrona $sanitizedSeat já está ocupada.");
          }
        }

        final savedId = await _passengerRepo.savePassenger(
          passenger.copyWith(name: sanitizedName, seatNumber: sanitizedSeat)
        );
        
        final finalVacancyRef = excursionRef.collection('vagas').doc(savedId);

        await _firestore.runTransaction((transaction) async {
          final vacancySnap = await transaction.get(finalVacancyRef);
          final bool isNew = !vacancySnap.exists;
          final bool wasPaid = isNew ? false : (vacancySnap.data()?['isPaid'] ?? false);

          transaction.set(finalVacancyRef, {
            'id': savedId,
            'poltrona': sanitizedSeat,
            'depositValue': validDeposit,
            'isPaid': isFullyPaid,
            'statusEmbarque': BoardingStatus.aguardando.value,
            'lastUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Atualiza contadores da excursão baseado na mudança de estado
          if (isNew) {
            transaction.update(excursionRef, {
              'assentosReservados': FieldValue.increment(1),
              if (isFullyPaid) 'assentosPagos': FieldValue.increment(1),
            });
          } else if (!wasPaid && isFullyPaid) {
            // Se já existia mas acabou de pagar agora
            transaction.update(excursionRef, {'assentosPagos': FieldValue.increment(1)});
          } else if (wasPaid && !isFullyPaid) {
            // Se estava pago e o valor foi reduzido (raro, mas possível)
            transaction.update(excursionRef, {'assentosPagos': FieldValue.increment(-1)});
          }
        });
      } else {
        await _passengerRepo.savePassenger(
          passenger.copyWith(name: sanitizedName, seatNumber: sanitizedSeat)
        );
      }
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
    if (depositValue < 0) throw Exception("Valor inválido.");
    
    final double safeDeposit = depositValue > totalValue ? totalValue : depositValue;
    final String safeSeat = (seatNumber ?? '').trim().toUpperCase();

    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);
    final bool isFullyPaid = safeDeposit >= totalValue;

    try {
      await _firestore.runTransaction((transaction) async {
        transaction.set(vacancyRef, {
          'id': passengerId,
          'depositValue': safeDeposit,
          'isPaid': isFullyPaid,
          'poltrona': safeSeat,
          'dataReserva': FieldValue.serverTimestamp(),
          'statusEmbarque': BoardingStatus.aguardando.value,
        });
        
        transaction.update(masterRef, {
          'excursionId': excursionId,
          'poltrona': safeSeat,
          'lastUpdate': FieldValue.serverTimestamp(),
        });

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
        'excursionId': null,
        'poltrona': '',
        'depositValue': 0.0,
        'isPaid': false,
        'statusEmbarque': BoardingStatus.aguardando.value,
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

  /// OTIMIZADO: Busca passageiros em paralelo para melhor performance
  Stream<List<Passenger>> watchPassengersForExcursion(String excursionId) {
    return _firestore
        .collection('excursoes')
        .doc(excursionId)
        .collection('vagas')
        .snapshots()
        .asyncMap((snapshot) async {
          
          // Dispara todas as buscas simultaneamente (Parallel processing)
          Future<Passenger?> fetchMaster(QueryDocumentSnapshot<Object?> doc) async {
            final mestre = await _passengerRepo.getPassengerById(doc.id);
            if (mestre == null) return null;
            
            final docData = doc.data() as Map<String, dynamic>;
            // Remove FieldValues locais para evitar erros de conversão no model
            docData.removeWhere((key, value) => value is FieldValue);
            
            final combinedData = {...mestre.toMap(), ...docData};
            return Passenger.fromMap(doc.id, combinedData);
          }

          final results = await Future.wait(snapshot.docs.map(fetchMaster));
          
          final List<Passenger> passengers = results.whereType<Passenger>().toList();
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
    if (updates == null || updates.isEmpty) return;
    
    if (updates.containsKey('depositValue')) {
      final excursionDoc = await _firestore.collection('excursoes').doc(excursionId).get();
      final double basePrice = (excursionDoc.data()?['precoBase'] ?? 0.0).toDouble();
      final double newVal = (updates['depositValue'] as num).toDouble();
      
      if (newVal < 0) throw Exception("Valor negativo não permitido.");
      if (newVal > basePrice) updates['depositValue'] = basePrice;
    }

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
        batch.update(excursionRef, {
          'assentosPagos': FieldValue.increment(1),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
