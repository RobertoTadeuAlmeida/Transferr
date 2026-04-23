import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'user_service.dart';

class AuthService {
  final UserRepository _userRepo;
  final UserService _userService;

  AuthService(this._userRepo, this._userService);

  Stream<fb_auth.User?> get authStateChanges => _userRepo.authStateChanges;
  fb_auth.User? get currentUser => _userRepo.currentUser;

  Future<User?> getUserData(String uid) => _userRepo.getUserData(uid);
  Future<void> logout() => _userRepo.signOut();

  Future<void> saveUserData(User user) async {
    try {
      await _userService.saveUserData(user);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> switchActiveCompany(String uid, String newCompanyId) async {
    if (uid.isEmpty) throw "O ID do usuário não pode ser vazio.";
    try {
      String companyName = "Sem Empresa";
      if (newCompanyId.isNotEmpty) {
        companyName = await _userRepo.getCompanyName(newCompanyId);
      }
      await _userRepo.updateUserData(uid, {
        'company': newCompanyId,
        'companyName': companyName,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  /// Transforma o usuário em Proprietário (OWNER) de sua própria agência (SaaS).
  Future<void> createOwnCompany(User user, String companyName) async {
    try {
      final String uid = user.id;
      final Set<String> updatedCompanies = Set<String>.from(user.companies)..add(uid);
      final Map<String, String> updatedRoles = Map.from(user.roles);
      updatedRoles[uid] = 'OWNER';

      final updatedUser = user.copyWith(
        company: uid,
        companyName: companyName.trim(),
        companies: updatedCompanies.toList(),
        roles: updatedRoles,
        profile: 'OWNER',
      );

      await _userService.saveUserData(updatedUser);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> register(User user, String password) async {
    fb_auth.UserCredential? userCredential;
    try {
      // 1. VALIDAÇÃO PREVENTIVA (Index do Firestore)
      // Verifica CPF/CNPJ e E-mail antes de criar a conta no Auth
      final docError = await _userService.validateDocumentUniqueness(user.document, '');
      if (docError != null) throw docError;

      final emailError = await _userService.validateEmailUniqueness(user.email, '');
      if (emailError != null) throw emailError;

      // 2. Cria usuário no Firebase Auth
      try {
        userCredential = await _userRepo.signUp(user.email, password);
        await userCredential.user?.reload();
        await Future.delayed(const Duration(milliseconds: 500));
      } on fb_auth.FirebaseAuthException catch (e) {
        throw _handleAuthError(e);
      }

      final String uid = userCredential.user!.uid;

      // 3. Define Perfil (OWNER se criar agência, AGENTE se for convite)
      final bool isCreatingCompany = user.companyName.isNotEmpty && user.companyName != 'Aguardando Vínculo';

      final newUser = user.copyWith(
        id: uid,
        company: isCreatingCompany ? uid : '',
        companyName: isCreatingCompany ? user.companyName : 'Aguardando Vínculo',
        companies: isCreatingCompany ? [uid] : [],
        roles: isCreatingCompany ? {uid: 'OWNER'} : {},
        profile: isCreatingCompany ? 'OWNER' : 'AGENTE',
        isActive: true,
        createdAt: DateTime.now(),
      );

      try {
        // 4. Salva no Firestore (Perfil + Índices de Unicidade)
        await _userService.saveUserData(newUser);
        await userCredential.user?.updateDisplayName(user.name);
      } catch (e) {
        // ROLLBACK: Se falhar no Firestore, remove do Auth para não deixar lixo
        await _userRepo.deleteAuthUser(userCredential.user);
        throw "Erro ao finalizar cadastro: $e";
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.trim().isEmpty) throw "E-mail e senha são obrigatórios.";
    try {
      final credential = await _userRepo.signIn(cleanEmail, password);
      final uid = credential.user?.uid;
      if (uid != null) {
        final userData = await _userRepo.getUserData(uid);
        if (userData == null) {
          await logout();
          throw "Perfil de usuário não encontrado.";
        }
        if (!userData.isActive) {
          await logout();
          throw "Sua conta global está desativada.";
        }
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  String _handleAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return "E-mail não cadastrado.";
      case 'wrong-password': return "Senha incorreta.";
      case 'email-already-in-use': return "Este e-mail já está sendo usado por outra conta.";
      case 'invalid-email': return "O formato do e-mail é inválido.";
      case 'weak-password': return "A senha fornecida é muito fraca.";
      default: return "Erro ao entrar: ${e.message}";
    }
  }

  Future<void> respondToInvite(String inviteId, String status, User currentUser, String companyId) async {
    try {
      await _userService.respondToInvite(
        inviteId: inviteId,
        status: status,
        currentUser: currentUser,
        companyId: companyId,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> transferOwnership(User currentOwner, String targetUserId, String companyId) async {
    try {
      await _userService.transferOwnership(
        currentOwner: currentOwner,
        targetUserId: targetUserId,
        companyId: companyId,
      );
    } catch (e) {
      throw e.toString();
    }
  }
}
