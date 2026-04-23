import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class UserRepository {
  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  final String _collection = 'usuario';
  final String _indexCollection = 'user_index';

  UserRepository({
    fb_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();
  fb_auth.User? get currentUser => _auth.currentUser;

  CollectionReference<User> get _userRef => _firestore
      .collection(_collection)
      .withConverter<User>(
        fromFirestore: (snapshot, _) => User.fromMap(snapshot.id, snapshot.data()!),
        toFirestore: (user, _) => user.toMap(),
      );

  // AUTH ACTIONS
  Future<fb_auth.UserCredential> signIn(String email, String password) async => 
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
  
  Future<fb_auth.UserCredential> signUp(String email, String password) async => 
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
  
  Future<void> signOut() async => await _auth.signOut();

  Future<void> deleteAuthUser(fb_auth.User? user) async {
    if (user != null) await user.delete();
  }

  // DATA ACTIONS (ATOMIC WITH INDEX)
  
  Future<void> saveUserDataWithIndex(User user, {bool isNewUser = false}) async {
    final batch = _firestore.batch();
    
    // 1. Usuário
    final userDoc = _userRef.doc(user.id);
    batch.set(userDoc, user, SetOptions(merge: true));

    // 2. Índice de CPF/CNPJ
    if (user.document.isNotEmpty) {
      final cleanDoc = user.document.replaceAll(RegExp(r'[^0-9]'), '');
      final indexDoc = _firestore.collection(_indexCollection).doc('doc_$cleanDoc');
      
      batch.set(indexDoc, {
        'uid': user.id,
        'type': 'documento',
        'value': user.document,
      }, SetOptions(merge: true));
    }

    // 3. Índice de Email
    if (user.email.isNotEmpty) {
      final emailId = 'email_${user.email.toLowerCase().trim()}';
      final indexEmail = _firestore.collection(_indexCollection).doc(emailId);
      
      batch.set(indexEmail, {
        'uid': user.id,
        'type': 'email',
        'value': user.email.toLowerCase().trim(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> saveUserData(User user) async => 
      await _userRef.doc(user.id).set(user, SetOptions(merge: true));
  
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async =>
      await _firestore.collection(_collection).doc(uid).update(data);

  Future<void> updateUserField(String uid, String field, dynamic value) async =>
      await _firestore.collection(_collection).doc(uid).update({field: value});

  Future<User?> getUserData(String uid) async => (await _userRef.doc(uid).get()).data();

  // INDEX ACTIONS
  
  Future<String?> getOwnerUidFromIndex(String indexId) async {
    final doc = await _firestore.collection(_indexCollection).doc(indexId).get();
    if (!doc.exists) return null;
    return doc.data()?['uid'] as String?;
  }

  Future<String> getCompanyName(String companyId) async {
    if (companyId.isEmpty) return 'Sem Empresa';
    final doc = await _firestore.collection(_collection).doc(companyId).get();
    return doc.data()?['nomeEmpresa'] ?? doc.data()?['nome'] ?? 'Empresa Sem Nome';
  }

  Future<User?> getUserByEmail(String email) async {
    final snap = await _userRef.where('email', isEqualTo: email.trim().toLowerCase()).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  Future<User?> getUserByDocument(String document) async {
    final snap = await _userRef.where('documento', isEqualTo: document.trim()).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  Stream<List<User>> getUsersStream(String companyId) {
    return _userRef.where('empresas', arrayContains: companyId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => doc.data()).where((u) => u.isActive).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  // INVITES
  Future<void> sendInvite({required String fromCompanyId, required String fromCompanyName, required String toUserId}) async {
    await _firestore.collection('convites').add({
      'fromCompanyId': fromCompanyId,
      'fromCompanyName': fromCompanyName,
      'toUserId': toUserId,
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) {
    return _firestore.collection('convites').where('toUserId', isEqualTo: userId).where('status', isEqualTo: 'pendente').snapshots().map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> respondToInvite(String inviteId, String status) async {
    await _firestore.collection('convites').doc(inviteId).update({'status': status.toLowerCase(), 'respondidoEm': FieldValue.serverTimestamp()});
  }
}
