import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/excursion.dart';

class ExcursionRepository {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'excursions',
  );

  Future<void> addExcursion(Excursion excursion) async {
    await _db.add(excursion.toMap());
  }

  Stream<List<Excursion>> getExcursionsStream() {
    return _db.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Excursion.fromFirestore(doc);
      }).toList();
    });
  }


  Future<void> updateExcursion(Excursion excursion) async {
    await _db.doc(excursion.id).update(excursion.toMap());
  }

  Future<void> deleteExcursion(Excursion excursion) async {
    await _db.doc(excursion.id).delete();
  }
}
