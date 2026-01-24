import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/excursion.dart';
import '../models/passenger.dart';

class ExcursionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referência base para facilitar o acesso
  CollectionReference<Map<String, dynamic>> get _excursionsRef =>
      _firestore.collection('excursoes');

  // --- MÉTODOS DE EXCURSÃO ---

  /// Escuta mudanças nas excursões filtrando pelo responsável (segurança)
  /// Se você não quiser filtrar agora, remova o .where()
  Stream<List<Excursion>> getExcursionsStream({String? responsibleId}) {
    Query<Map<String, dynamic>> query = _excursionsRef;

    if (responsibleId != null) {
      query = query.where('idResponsavel', isEqualTo: responsibleId);
    }

    return query
        .orderBy('dataPartida', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Excursion.fromFirestore(doc))
        .toList());
  }

  Future<void> addExcursion(Excursion excursion) async {
    try {
      // Limpamos o mapa para evitar erros de tipos (Pigeon) e campos nulos
      final data = _cleanMap(excursion.toMap());
      await _excursionsRef.add(data);
    } catch (e) {
      debugPrint("Erro ao adicionar no Firestore: $e");
      rethrow;
    }
  }

  Future<void> updateExcursion(Excursion excursion) async {
    if (excursion.id == null) return;
    try {
      final data = _cleanMap(excursion.toMap());
      await _excursionsRef.doc(excursion.id).update(data);
    } catch (e) {
      debugPrint("Erro ao atualizar no Firestore: $e");
      rethrow;
    }
  }

  /// Deleta múltiplas excursões usando WriteBatch
  Future<void> deleteMultipleExcursions(List<String> ids) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      batch.delete(_excursionsRef.doc(id));
    }
    await batch.commit();
  }

  // --- MÉTODOS DE PASSAGEIROS (SUB-COLEÇÃO) ---

  CollectionReference<Map<String, dynamic>> _vagasRef(String excursionId) =>
      _excursionsRef.doc(excursionId).collection('vagas');

  Stream<List<Passenger>> getPassengersStream(String excursionId) {
    return _vagasRef(excursionId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Passenger.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Adiciona/Atualiza passageiro e incrementa contador de vagas atômico
  Future<void> addOrUpdatePassenger(String excursionId, Passenger passenger) async {
    final passengerDocRef = _vagasRef(excursionId).doc(passenger.id);

    return _firestore.runTransaction((transaction) async {
      final passengerSnapshot = await transaction.get(passengerDocRef);

      // Limpamos o mapa do passageiro também
      final pData = _cleanMap(passenger.toMap());

      transaction.set(passengerDocRef, pData, SetOptions(merge: true));

      if (!passengerSnapshot.exists) {
        transaction.update(_excursionsRef.doc(excursionId), {
          'assentosReservados': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> updateCheckinStatus({
    required String excursionId,
    required String passengerId,
    required Map<String, dynamic> checkinData,
  }) async {
    try {
      final cleanData = _cleanMap(checkinData);
      await _vagasRef(excursionId).doc(passengerId).update(cleanData);
    } catch (e) {
      rethrow;
    }
  }

  // --- UTILITÁRIOS ---

  /// Remove valores nulos do Map para evitar o erro:
  /// "type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'"
  Map<String, dynamic> _cleanMap(Map<String, dynamic> data) {
    final Map<String, dynamic> clean = {};
    data.forEach((key, value) {
      if (value != null) {
        clean[key] = value;
      }
    });
    return clean;
  }
}