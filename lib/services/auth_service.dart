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

  /// Salva os dados do usuário delegando ao [UserService] para garantir
  /// validações de documento único e sanitização.
  Future<void> saveUserData(User user) async {
    try {
      await _userService.saveUserData(user);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Altera a empresa ativa do usuário.
  Future<void> switchActiveCompany(String uid, String newCompanyId) async {
    if (uid.isEmpty) throw "O ID do usuário não pode ser vazio.";
    try {
      String companyName = "Sem Empresa";
      if (newCompanyId.isNotEmpty) {
        companyName = await _userRepo.getCompanyName(newCompanyId);
      }

      await _userRepo.updateUserData(uid, {
        'empresa': newCompanyId,
        'nomeEmpresa': companyName,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  /// Transforma o usuário em um Proprietário (ADMIN), criando sua própria agência.
  Future<void> createOwnCompany(User user, String companyName) async {
    try {
      final String uid = user.id;

      // Garante unicidade e imutabilidade dos papéis
      final updatedCompanies = Set<String>.from(user.companies)..add(uid);
      final updatedRoles = Map<String, String>.from(user.roles)..[uid] = 'ADMIN';

      final updatedUser = user.copyWith(
        company: uid,
        companyName: companyName.trim(),
        companies: updatedCompanies.toList(),
        roles: updatedRoles,
        profile: 'ADMIN',
      );

      await _userService.saveUserData(updatedUser);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Realiza o registro completo: Auth -> Validações de Domínio -> Firestore.
  Future<void> register(User user, String password) async {
    fb_auth.UserCredential? userCredential;
    
    try {
      await _userService.isDocumentUnique(user.document, '');

      userCredential = await _userRepo.signUp(user.email, password);
      final String uid = userCredential.user!.uid;
      
      final bool isAdmin = user.profile.toUpperCase() == 'ADMIN';
      
      final newUser = user.copyWith(
        id: uid,
        company: isAdmin ? uid : '',
        companyName: isAdmin ? user.company : 'Aguardando Vínculo',
        companies: isAdmin ? [uid] : [],
        roles: isAdmin ? {uid: 'ADMIN'} : {},
      );

      try {
        await _userService.saveUserData(newUser);
        await userCredential.user?.updateDisplayName(user.name);
      } catch (e) {
        if (userCredential?.user != null) {
          await _userRepo.deleteAuthUser(userCredential!.user);
        }
        throw e.toString();
      }
    } catch (e) {
      throw e.toString();
    }
  }

  /// Realiza o login e valida o estado da conta.
  /// Se o usuário não tiver empresa (foi desligado), o login é permitido 
  /// para que a UI possa exibir a mensagem correta (ex: "Aguardando Vínculo").
  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    
    if (cleanEmail.isEmpty || password.trim().isEmpty) {
      throw "E-mail e senha são obrigatórios.";
    }

    try {
      final credential = await _userRepo.signIn(cleanEmail, password);
      final uid = credential.user?.uid;

      if (uid != null) {
        final userData = await _userRepo.getUserData(uid);
        
        // Regra 1: Usuário não existe no Firestore (Inconsistência)
        if (userData == null) {
          await logout();
          throw "Perfil de usuário não encontrado. Entre em contato.";
        }

        // Regra 2: Bloqueio Global (Banido do App)
        if (!userData.isActive) {
          await logout();
          throw "Sua conta global está desativada.";
        }

        // Regra 3: Se não tem empresa (foi desvinculado), o login CONTINUA.
        // A UI deve tratar isso verificando se companies.isEmpty ou 
        // se companyName == "Aguardando Vínculo".
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Centraliza as mensagens de erro do Firebase Auth
  String _handleAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return "E-mail não cadastrado.";
      case 'wrong-password': return "Senha incorreta.";
      case 'user-disabled': return "Este usuário foi banido pelo Firebase.";
      case 'invalid-email': return "Formato de e-mail inválido.";
      default: return "Erro ao entrar: ${e.message}";
    }
  }
}
