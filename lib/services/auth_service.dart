import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthService {
  final UserRepository _userRepo;

  AuthService(this._userRepo);

  Stream<fb_auth.User?> get authStateChanges => _userRepo.authStateChanges;
  fb_auth.User? get currentUser => fb_auth.FirebaseAuth.instance.currentUser;

  Future<User?> getUserData(String uid) => _userRepo.getUserData(uid);
  Future<void> logout() => _userRepo.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Troca a empresa ativa e garante que o nome da nova empresa seja buscado
  Future<void> switchActiveCompany(String uid, String newCompanyId) async {
    try {
      String newName = "Sem Empresa";
      if (newCompanyId.isNotEmpty) {
        newName = await _userRepo.getCompanyName(newCompanyId);
      }

      await _userRepo.updateUserData(uid, {
        'empresa': newCompanyId,
        'nomeEmpresa': newName,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> register(User user, String password) async {
    // REGRA: Usuários comuns precisam estar vinculados a uma empresa no cadastro
    if (!user.isAdmin && user.company.isEmpty) {
      throw Exception("Obrigatório vincular-se a uma empresa para realizar o cadastro.");
    }

    fb_auth.UserCredential? userCredential;
    try {
      userCredential = await _userRepo.signUp(user.email, password);
      final String uid = userCredential.user!.uid;
      
      // ADMIN: Dono da empresa (ID = seu UID). Agente: Usa o ID fornecido.
      final String companyId = user.isAdmin ? uid : user.company;
      
      // Se for ADMIN, o texto digitado no campo empresa é o nome fantasia.
      // Se for Agente, ele entra como "Aguardando Vínculo" até carregar o nome real.
      final String companyName = user.isAdmin ? user.company : "Aguardando Vínculo";

      final userWithId = user.copyWith(
        id: uid,
        company: companyId,
        companyName: companyName,
        companies: [companyId], 
      );

      await _userRepo.saveUserData(userWithId);
      await userCredential.user?.updateDisplayName(user.name);
    } catch (e) {
      if (userCredential?.user != null) {
        await _userRepo.deleteAuthUser(userCredential!.user);
      }
      throw _handleError(e);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _userRepo.signIn(email, password);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateProfile({required String name, String? photoUrl}) async {
    final user = currentUser;
    if (user == null) throw Exception("Nenhum usuário logado.");
    try {
      await user.updateDisplayName(name);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await _userRepo.updateUserData(user.uid, {
        'nome': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic e) {
    if (e is fb_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use': return 'Este e-mail já está em uso.';
        case 'network-request-failed': return 'Erro de conexão com a internet.';
        default: return e.message ?? 'Erro inesperado na autenticação.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
