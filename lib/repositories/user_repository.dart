import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'usuario';

  /// Salva ou atualiza os dados do usuário no Firestore
  Future<void> saveUser(User user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception("Erro ao salvar usuário: $e");
    }
  }

  /// Busca um usuário específico pelo ID
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception("Erro ao buscar usuário: $e");
    }
  }

  /// Stream para listar todos os usuários da empresa (Útil para Admins)
  Stream<List<User>> getUsersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nome') // Ajustado de 'name' para 'nome' (conforme seu toMap)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => User.fromFirestore(doc))
        .toList());
  }

  /// Ativa ou Desativa um usuário (Soft Delete)
  Future<void> toggleUserStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive, // Mantido isActive (booleano)
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erro ao alterar status: $e");
    }
  }

  /// Atualiza o perfil do usuário (ADMIN ou AGENTE)
  Future<void> updateUserRole(String id, String roleName) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'perfil': roleName.toUpperCase(), // Ajustado para 'perfil' (conforme seu toMap)
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Erro ao atualizar cargo: $e");
    }
  }
}