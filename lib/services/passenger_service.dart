import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import '../models/passenger.dart';
import '../repositories/passenger_repository.dart';

class PassengerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PassengerRepository _passengerRepo;

  PassengerService(this._passengerRepo);

  // ===========================================================================
  // SALVAMENTO COMPLETO (CRM + VAGA)
  // ===========================================================================

  Future<void> savePassenger({
    required Passenger passenger,
    String? excursionId,
    double? depositValue,
  }) async {
    debugPrint("💾 SERVICE: Iniciando salvamento de ${passenger.name}");

    try {
      // 1. REGRA DE NEGÓCIO: Verificar se a poltrona já está ocupada nesta excursão
      if (excursionId != null && passenger.seatNumber.isNotEmpty) {
        final seatConflict = await _firestore
            .collection('excursoes')
            .doc(excursionId)
            .collection('vagas')
            .where('poltrona', isEqualTo: passenger.seatNumber)
            .get();

        // Se houver conflito e não for o próprio passageiro sendo editado
        if (seatConflict.docs.isNotEmpty &&
            seatConflict.docs.first.id != passenger.id) {
          throw Exception(
            "A poltrona ${passenger.seatNumber} já está ocupada por outro passageiro.",
          );
        }
      }

      // 2. SALVAR NO CRM (Base Mestre) via Repository
      // O repository já cuida de colocar o userId e timestamps
      final savedId = await _passengerRepo.savePassenger(passenger);

      // 3. SE HOUVER EXCURSÃO, ATUALIZA A VAGA E CONTADORES
      if (excursionId != null) {
        final excursionRef = _firestore
            .collection('excursoes')
            .doc(excursionId);
        final vacancyRef = excursionRef.collection('vagas').doc(savedId);

        // Buscamos a excursão para saber o valor total (opcional, dependendo da sua lógica)
        final excursionDoc = await excursionRef.get();
        final double totalValue = (excursionDoc.data()?['valor'] ?? 0.0)
            .toDouble();
        final bool isFullyPaid = (depositValue ?? 0.0) >= totalValue;

        await _firestore.runTransaction((transaction) async {
          // Verifica se a vaga já existe para saber se incrementa ou apenas atualiza
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

          // Atualiza contadores da excursão apenas se for uma nova vaga
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
  // VÍNCULO E OPERAÇÃO (EXCURSÕES)
  // ===========================================================================

  /// Vincula um passageiro a uma excursão atualizando os 2 contadores
  Future<void> linkToExcursion({
    required String passengerId,
    required String excursionId,
    required double depositValue,
    required double totalValue,
    required String? seatNumber,
  }) async {
    debugPrint(
      "🔗 SERVICE: Vinculando passageiro $passengerId à excursão $excursionId",
    );

    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);

    final bool isFullyPaid = depositValue >= totalValue;

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Registro na sub-coleção 'vagas'
        transaction.set(vacancyRef, {
          'id': passengerId,
          'depositValue': depositValue,
          'isPaid': isFullyPaid,
          'poltrona': seatNumber,
          'dataReserva': FieldValue.serverTimestamp(),
          'statusEmbarque': 'Pendente',
        });

        // 2. Marca no CRM
        transaction.update(masterRef, {'excursionId': excursionId});

        // 3. Incrementa contadores
        transaction.update(excursionRef, {
          'assentosReservados': FieldValue.increment(1),
          if (isFullyPaid) 'assentosPagos': FieldValue.increment(1),
        });
      });
      debugPrint("✅ SERVICE: Vínculo concluído com sucesso.");
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (linkToExcursion): $e");
      rethrow;
    }
  }

  /// Desvincula um passageiro de uma excursão
  Future<void> unlinkFromExcursion({
    required String passengerId,
    required String excursionId,
  }) async {
    debugPrint(
      "🔓 SERVICE: Desvinculando passageiro $passengerId da excursão $excursionId",
    );

    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = excursionRef.collection('vagas').doc(passengerId);
    final masterRef = _firestore.collection('passageiros').doc(passengerId);

    try {
      final vacancyDoc = await vacancyRef.get();
      if (!vacancyDoc.exists) {
        debugPrint("⚠️ SERVICE: Vaga não encontrada para remoção.");
        return;
      }

      final bool wasPaid = vacancyDoc.data()?['isPaid'] ?? false;
      final batch = _firestore.batch();

      // Deleta a vaga
      batch.delete(vacancyRef);

      // Limpa dados no CRM
      batch.update(masterRef, {
        'excursionId': '',
        'seatNumber': '',
        'depositValue': 0.0,
        'isPaid': false,
        'statusEmbarque': 'Pendente',
      });

      // Decrementa contadores da excursão
      batch.update(excursionRef, {
        'assentosReservados': FieldValue.increment(-1),
        if (wasPaid) 'assentosPagos': FieldValue.increment(-1),
      });

      await batch.commit();
      debugPrint("✅ SERVICE: Desvinculação concluída (wasPaid: $wasPaid)");
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (unlinkFromExcursion): $e");
      rethrow;
    }
  }

  /// Ouve os passageiros de uma excursão validando o pertencimento ao usuário
  Stream<List<Passenger>> watchPassengersForExcursion(String excursionId) {
    debugPrint(
      "📡 SERVICE: Iniciando watch para vagas da excursão $excursionId",
    );

    return _firestore
        .collection('excursoes')
        .doc(excursionId)
        .collection('vagas')
        .snapshots()
        .asyncMap((snapshot) async {
          debugPrint(
            "📦 SERVICE: Snapshot de vagas recebido (${snapshot.docs.length} documentos)",
          );

          List<Passenger> passengers = [];

          for (var doc in snapshot.docs) {
            // O getPassengerById do Repository já filtra pelo userId do organizador
            final mestre = await _passengerRepo.getPassengerById(doc.id);

            if (mestre != null) {
              final docData = doc.data();
              // Remove FieldValue para evitar erros de cast no fromMap
              docData.removeWhere((key, value) => value is FieldValue);

              final combinedData = {...mestre.toMap(), ...docData};
              passengers.add(Passenger.fromMap(doc.id, combinedData));
            } else {
              // Se mestre for null, é porque o passageiro pertence a outro usuário ou foi deletado
              debugPrint(
                "⚠️ SERVICE: Vaga ignorada (ID: ${doc.id}). Motivo: Passageiro órfão ou de outro usuário.",
              );
            }
          }

          passengers.sort((a, b) => a.name.compareTo(b.name));
          debugPrint(
            "👥 SERVICE: Lista final processada: ${passengers.length} passageiros visíveis.",
          );
          return passengers;
        });
  }

  /// Atualiza o status operacional e financeiro com logs
  Future<void> updateOperationalStatus({
    required String passengerId,
    required String excursionId,
    Map<String, dynamic>? updates,
    bool? justFinishedPaying,
  }) async {
    if (updates == null) return;
    debugPrint("📝 SERVICE: Atualizando status operacional para $passengerId");

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
        debugPrint("💰 SERVICE: Incrementando contador de assentos pagos.");
        batch.update(excursionRef, {'assentosPagos': FieldValue.increment(1)});
      }

      await batch.commit();
      debugPrint("✅ SERVICE: Atualização operacional concluída.");
    } catch (e) {
      debugPrint("❌ SERVICE ERROR (updateOperationalStatus): $e");
      rethrow;
    }
  }

  /// Finaliza a viagem: Limpa o status ativo e incrementa o histórico
  Future<void> finalizeTrip(String passengerId) async {
    debugPrint("🏁 SERVICE: Finalizando viagem para o passageiro $passengerId");
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
