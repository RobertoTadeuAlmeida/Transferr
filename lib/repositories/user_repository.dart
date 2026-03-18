import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'usuario';
  final String _invitesCollection = 'convites';

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  CollectionReference<User> get _userRef => _firestore
      .collection(_collection)
      .withConverter<User>(
        fromFirestore: (snapshot, _) => User.fromMap(snapshot.id, snapshot.data()!),
        toFirestore: (user, _) => user.toMap(),
      );

  // --- MÉTODOS DE AUTHENTICATION ---
  Future<fb_auth.UserCredential> signIn(String email, String password) async => await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
  Future<fb_auth.UserCredential> signUp(String email, String password) async => await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
  Future<void> signOut() async => await _auth.signOut();
  Future<void> deleteAuthUser(fb_auth.User? user) async { if (user != null) await user.delete(); }

  // --- MÉTODOS DE USUÁRIO ---
  Future<void> saveUserData(User user) async => await _userRef.doc(user.id).set(user, SetOptions(merge: true));
  
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    final Map<String, dynamic> updates = Map.from(data);
    updates['atualizadoEm'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(uid).update(updates);
  }

  Future<User?> getUserData(String uid) async => (await _userRef.doc(uid).get()).data();

  Future<String> getCompanyName(String companyId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(companyId).get();
      if (doc.exists) {
        return doc.data()?['nomeEmpresa'] ?? doc.data()?['nome'] ?? 'Empresa Sem Nome';
      }
      return 'Empresa Desconhecida';
    } catch (e) {
      return 'Empresa ID: ${companyId.characters.take(5)}...';
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final snap = await _userRef.where('email', isEqualTo: email.trim().toLowerCase()).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  // --- MÉTODOS DE EQUIPE ---

  /// Retorna todos os usuários que fazem parte de uma empresa específica.
  /// OTIMIZAÇÃO: Filtragem de isActive e Ordenação feitas na memória para evitar erros de Índice Composto e permissão.
  Stream<List<User>> getUsersStream(String companyId) => _userRef
      .where('empresas', arrayContains: companyId)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => doc.data())
            .where((u) => u.isActive) // Filtro na memória
            .toList();
            
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Future<void> toggleUserStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // --- SISTEMA DE CONVITES ---

  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserId,
  }) async {
    final existing = await _firestore.collection(_invitesCollection)
        .where('fromCompanyId', isEqualTo: fromCompanyId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pendente')
        .limit(1).get();

    if (existing.docs.isNotEmpty) return;

    await _firestore.collection(_invitesCollection).add({
      'fromCompanyId': fromCompanyId,
      'fromCompanyName': fromCompanyName,
      'toUserId': toUserId,
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) {
    return _firestore
        .collection(_invitesCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pendente')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> respondToInvite(String inviteId, String status) async {
    await _firestore.collection(_invitesCollection).doc(inviteId).update({
      'status': status,
      'respondidoEm': FieldValue.serverTimestamp(),
    });
  }
}
