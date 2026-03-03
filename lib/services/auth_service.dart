import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
import '../repositories/user_repository.dart'; // Importação atualizada

class AuthService {
  final UserRepository _userRepo; // Repositório unificado

  AuthService(this._userRepo);

  /// Orquestra o Cadastro Completo: Auth + Firestore + Metadados + Rollback
  Future<void> register(User user, String password) async {
    fb_auth.UserCredential? userCredential;

    try {
      // 1. Criar no Firebase Auth (Apenas credenciais)
      userCredential = await _userRepo.signUp(user.email, password);
      final String uid = userCredential.user!.uid;

      // 2. Preparar modelo com o UID gerado e ID da empresa
      // Se a empresa não for passada, usamos o próprio UID (padrão para novos Admins)
      final userWithId = user.copyWith(
        id: uid,
        company: user.company.isEmpty ? uid : user.company,
      );

      // 3. Salvar os dados complementares no Firestore via UserRepository
      await _userRepo.saveUserData(userWithId);

      // 4. Atualizar metadados do Firebase Auth (facilita identificação no console)
      await userCredential.user?.updateDisplayName(user.name);

    } catch (e) {
      // ROLLBACK: Se o Firestore ou metadados falharem, removemos do Auth
      // para evitar usuários "fantasmas" (com login mas sem dados no banco)
      if (userCredential?.user != null) {
        await _userRepo.deleteAuthUser(userCredential!.user);
      }
      throw _handleError(e);
    }
  }

  /// Realiza o login utilizando o repositório
  Future<void> login(String email, String password) async {
    try {
      await _userRepo.signIn(email, password);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Tratamento de erros amigável para o usuário final
  String _handleError(dynamic e) {
    if (e is fb_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está sendo utilizado por outra conta.';
        case 'invalid-email':
          return 'O formato do e-mail é inválido.';
        case 'weak-password':
          return 'A senha fornecida é muito fraca.';
        case 'user-not-found':
          return 'Nenhum usuário encontrado com este e-mail.';
        case 'wrong-password':
          return 'Senha incorreta. Tente novamente.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente mais tarde.';
        default:
          return e.message ?? 'Ocorreu um erro inesperado na autenticação.';
      }
    }

    // Erros de permissão do Firestore ou rede
    if (e.toString().contains('permission-denied')) {
      return 'Você não tem permissão para realizar esta operação.';
    }

    return e.toString().replaceFirst('Exception: ', '');
  }
}