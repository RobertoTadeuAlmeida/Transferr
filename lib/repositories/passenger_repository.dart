import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  /// Salva ou atualiza um passageiro no CRM Global vinculado à empresa.
  Future<String> savePassenger(Passenger passenger) async {
    try {
      if (passenger.empresa.isEmpty) {
        throw Exception("Obrigatório informar a empresa para salvar o passageiro.");
      }

      final docRef = passenger.id.isEmpty
          ? _collection.doc()
          : _collection.doc(passenger.id);

      final data = passenger.toMap();
      data['id'] = docRef.id;
      data['criadoPor'] = _currentUserId; // Rastreabilidade: quem criou o registro
      data['lastUpdate'] = FieldValue.serverTimestamp();

      if (passenger.id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['totalViagens'] = 0;
      }

      debugPrint("💾 REPOSITORY: Salvando passageiro ${docRef.id} para a empresa ${passenger.empresa}");
      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      debugPrint("❌ REPOSITORY ERROR (save): $e");
      throw _handleError("salvar cadastro", e);
    }
  }

  /// Escuta os passageiros globais filtrados pela EMPRESA ativa.
  Stream<List<Passenger>> getGlobalPassengersStream(String companyId) {
    if (companyId.isEmpty) {
      debugPrint("🛑 REPOSITORY: Stream abortada. CompanyID vazio.");
      return Stream.value([]);
    }

    debugPrint("📡 REPOSITORY: Iniciando Stream de CRM para a empresa: $companyId");

    return _collection
        .where('empresa', isEqualTo: companyId) // Filtro Multi-tenant
        .orderBy('nome')
        .snapshots()
        .map((snapshot) {
      debugPrint("✅ REPOSITORY: CRM Snapshot recebido com ${snapshot.docs.length} documentos.");

      return snapshot.docs.map((doc) {
        try {
          return Passenger.fromMap(doc.id, doc.data());
        } catch (e) {
          debugPrint("❌ REPOSITORY ERROR (fromMap): Erro no documento ${doc.id}: $e");
          return Passenger(
              id: doc.id,
              empresa: companyId,
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
      return <Passenger>[];
    });
  }

  /// Busca um passageiro por ID, validando se ele pertence à empresa ativa.
  Future<Passenger?> getPassengerById(String passengerId, String companyId) async {
    try {
      final doc = await _collection.doc(passengerId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data?['empresa'] != companyId) {
        debugPrint("🚫 REPOSITORY: Tentativa de acesso negada a passageiro de outra empresa.");
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
