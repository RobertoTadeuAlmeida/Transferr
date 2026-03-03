import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class UserRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'usuario';

  // --- STREAM DE AUTENTICAÇÃO ---
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  // --- MÉTODOS DE AUTHENTICATION ---

  Future<fb_auth.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<fb_auth.UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> deleteAuthUser(fb_auth.User? user) async {
    if (user != null) await user.delete();
  }

  // --- MÉTODOS DE FIRESTORE (USUÁRIOS) ---

  Future<void> saveUserData(User user) async {
    final Map<String, dynamic> data = user.toMap();
    // Removemos nulos para evitar erros de tipo no Firestore
    data.removeWhere((key, value) => value == null);

    await _firestore
        .collection(_collection)
        .doc(user.id)
        .set(data, SetOptions(merge: true));
  }

  Future<User?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(uid)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    )
        .get();

    if (doc.exists && doc.data() != null) {
      return User.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Lista todos os usuários (Ex: para gestão de equipe)
  Stream<List<User>> getUsersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => User.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Soft delete ou bloqueio de acesso
  Future<void> toggleUserStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}