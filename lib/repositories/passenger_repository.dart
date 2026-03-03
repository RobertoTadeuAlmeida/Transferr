import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import '../models/passenger.dart';

class PassengerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter para o UID com log de verificação
  String get _currentUserId {
    final uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) {
      debugPrint("⚠️ REPOSITORY: Ninguém logado no Firebase Auth.");
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('passageiros');

  // ===========================================================================
  // 1. GESTÃO DE CADASTRO (CRM - BASE MESTRE)
  // ===========================================================================

  Future<String> savePassenger(Passenger passenger) async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) throw Exception("Usuário não autenticado.");

      final docRef = passenger.id.isEmpty
          ? _collection.doc()
          : _collection.doc(passenger.id);

      final data = passenger.toMap();
      data['id'] = docRef.id;
      data['userId'] = uid; // Garante o vínculo com o dono
      data['lastUpdate'] = FieldValue.serverTimestamp();

      if (passenger.id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['totalViagens'] = 0;
        data['excursaoId'] = null;
      }

      debugPrint("💾 REPOSITORY: Salvando passageiro ${docRef.id} para o usuário $uid");
      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint("❌ REPOSITORY ERROR (save): $e");
      throw _handleError("salvar cadastro", e);
    }
  }

  Stream<List<Passenger>> getGlobalPassengersStream() {
    final uid = _currentUserId;

    if (uid.isEmpty) {
      debugPrint("🛑 REPOSITORY: Stream abortada. UserID vazio.");
      return Stream.value([]);
    }

    debugPrint("📡 REPOSITORY: Iniciando Stream para o usuário: $uid");

    return _collection
        .where('userId', isEqualTo: uid)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) {
      debugPrint("✅ REPOSITORY: Snapshot recebido com ${snapshot.docs.length} documentos.");

      return snapshot.docs.map((doc) {
        try {
          return Passenger.fromMap(doc.id, doc.data());
        } catch (e) {
          debugPrint("❌ REPOSITORY ERROR (fromMap): Erro no documento ${doc.id}: $e");
          // Retorna um passageiro "dummy" para não quebrar a lista inteira por causa de um erro
          return Passenger(
              id: doc.id,
              name: "Erro de Dados (${doc.id})",
              document: "",
              phone: "",
              birthDate: DateTime.now()
          );
        }
      }).toList();
    })
        .handleError((error) {
      debugPrint("🔥 REPOSITORY STREAM CRITICAL ERROR: $error");
      // Se o erro for de índice, ele aparecerá aqui com o link para criar.
      return <Passenger>[];
    });
  }

  Future<Passenger?> getPassengerById(String passengerId) async {
    try {
      final doc = await _collection.doc(passengerId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data?['userId'] != _currentUserId) {
        debugPrint("🚫 REPOSITORY: Tentativa de acesso negada a passageiro de outro usuário.");
        return null;
      }

      return Passenger.fromMap(doc.id, data!);
    } catch (e) {
      debugPrint("❌ REPOSITORY ERROR (getById): $e");
      throw _handleError("buscar passageiro por ID", e);
    }
  }

  Future<void> updateMasterData(String passengerId, Map<String, dynamic> data) async {
    try {
      await _collection.doc(passengerId).update(data);
    } catch (e) {
      throw _handleError("atualizar dados mestre", e);
    }
  }

  Future<void> deletePassenger(String passengerId) async {
    try {
      await _collection.doc(passengerId).delete();
      debugPrint("🗑️ REPOSITORY: Passageiro $passengerId removido permanentemente.");
    } catch (e) {
      throw _handleError("remover passageiro", e);
    }
  }

  Exception _handleError(String acao, dynamic e) {
    return Exception("Erro ao $acao: $e");
  }
}