import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/passenger.dart';

class PassengerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PassengerRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? "";

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('passageiros');

  CollectionReference<Map<String, dynamic>> _vagasRef(String excursionId) =>
      _firestore.collection('excursoes').doc(excursionId).collection('vagas');

  Future<String> savePassenger(Passenger passenger) async {
    if (passenger.empresa.isEmpty) {
      throw Exception("Obrigatório informar a empresa para salvar o passageiro.");
    }

    final docRef = passenger.id.isEmpty ? _collection.doc() : _collection.doc(passenger.id);
    final data = passenger.toMap();
    
    data['id'] = docRef.id;
    data['criadoPor'] = _currentUserId;
    data['lastUpdate'] = FieldValue.serverTimestamp();

    if (passenger.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['totalViagens'] = 0;
    }

    await docRef.set(data, SetOptions(merge: true));
    return docRef.id;
  }

  /// Executa a quitação total via Batch
  Future<void> settleFullPaymentBatch({
    required String passengerId,
    required String excursionId,
    required double fullValue,
  }) async {
    final batch = _firestore.batch();
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final masterRef = _collection.doc(passengerId);
    final vacancyRef = _vagasRef(excursionId).doc(passengerId);

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
  }

  /// Executa o vínculo/atualização de vaga via Transação
  Future<void> runVacancyTransaction({
    required String excursionId,
    required String passengerId,
    required Map<String, dynamic> vacancyData,
    required bool isNew,
    required bool wasPaid,
    required bool isFullyPaid,
  }) async {
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = _vagasRef(excursionId).doc(passengerId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(vacancyRef, vacancyData, SetOptions(merge: true));

      if (isNew) {
        transaction.update(excursionRef, {
          'assentosReservados': FieldValue.increment(1),
          if (isFullyPaid) 'assentosPagos': FieldValue.increment(1),
        });
      } else {
        if (!wasPaid && isFullyPaid) {
          transaction.update(excursionRef, {'assentosPagos': FieldValue.increment(1)});
        } else if (wasPaid && !isFullyPaid) {
          transaction.update(excursionRef, {'assentosPagos': FieldValue.increment(-1)});
        }
      }
    });
  }

  /// Desvincula o passageiro via Batch
  Future<void> unlinkFromExcursionBatch({
    required String passengerId,
    required String excursionId,
    required bool wasPaid,
  }) async {
    final batch = _firestore.batch();
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);
    final vacancyRef = _vagasRef(excursionId).doc(passengerId);
    final masterRef = _collection.doc(passengerId);

    batch.delete(vacancyRef);
    batch.update(masterRef, {
      'excursionId': null,
      'poltrona': '',
      'depositValue': 0.0,
      'isPaid': false,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    batch.update(excursionRef, {
      'assentosReservados': FieldValue.increment(-1),
      if (wasPaid) 'assentosPagos': FieldValue.increment(-1),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Atualiza dados operacionais via Batch
  Future<void> updateOperationalBatch({
    required String passengerId,
    required String excursionId,
    required Map<String, dynamic> updates,
    bool incrementPaidCount = false,
  }) async {
    final batch = _firestore.batch();
    final masterRef = _collection.doc(passengerId);
    final vacancyRef = _vagasRef(excursionId).doc(passengerId);
    final excursionRef = _firestore.collection('excursoes').doc(excursionId);

    batch.update(masterRef, updates);
    batch.update(vacancyRef, updates);

    if (incrementPaidCount) {
      batch.update(excursionRef, {
        'assentosPagos': FieldValue.increment(1),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    return _collection
        .where('empresa', isEqualTo: companyId)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Passenger.fromMap(doc.id, doc.data())).toList());
  }

  Future<Passenger?> getPassengerById(String passengerId, String companyId) async {
    final doc = await _collection.doc(passengerId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['empresa'] != companyId) return null;
    return Passenger.fromMap(doc.id, data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getVacancyDoc(String excursionId, String passengerId) {
    return _vagasRef(excursionId).doc(passengerId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchVacancies(String excursionId) {
    return _vagasRef(excursionId).snapshots();
  }

  Future<void> deletePassenger(String passengerId) async {
    await _collection.doc(passengerId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> findSeatConflict(String excursionId, String seat) {
    return _vagasRef(excursionId).where('poltrona', isEqualTo: seat).get();
  }
}
