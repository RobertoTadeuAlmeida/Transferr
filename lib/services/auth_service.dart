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

  Future<void> saveUserData(User user) => _userRepo.saveUserData(user);

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
      throw e.toString();
    }
  }

  /// Transforma um Agente em Admin criando sua própria empresa
  Future<void> createOwnCompany(User user, String companyName) async {
    final String uid = user.id;
    
    // Novo mapa de papéis incluindo a si mesmo como ADMIN da nova empresa
    final Map<String, String> updatedRoles = Map.from(user.roles);
    updatedRoles[uid] = 'ADMIN';

    final List<String> updatedCompanies = List.from(user.companies);
    if (!updatedCompanies.contains(uid)) {
      updatedCompanies.add(uid);
    }

    final updatedUser = user.copyWith(
      company: uid,
      companyName: companyName,
      companies: updatedCompanies,
      roles: updatedRoles,
      profile: 'ADMIN', // Ele passa a ser Admin globalmente também
    );

    await _userRepo.saveUserData(updatedUser);
  }

  Future<void> register(User user, String password) async {
    fb_auth.UserCredential? userCredential;
    try {
      userCredential = await _userRepo.signUp(user.email, password);
      final String uid = userCredential.user!.uid;
      
      // LOGICA MULTI-ROLE:
      Map<String, String> roles = {};
      String companyId = "";
      String companyName = "Aguardando Vínculo";
      List<String> companies = [];

      if (user.profile == 'ADMIN') {
        companyId = uid;
        companyName = user.company; // O campo company aqui veio do form como nome
        companies = [uid];
        roles[uid] = 'ADMIN';
      }

      final userWithId = user.copyWith(
        id: uid,
        company: companyId,
        companyName: companyName,
        companies: companies,
        roles: roles,
      );

      await _userRepo.saveUserData(userWithId);
      await userCredential.user?.updateDisplayName(user.name);
    } catch (e) {
      if (userCredential?.user != null) {
        await _userRepo.deleteAuthUser(userCredential!.user);
      }
      throw e.toString();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _userRepo.signIn(email, password);
    } catch (e) {
      throw e.toString();
    }
  }
}
