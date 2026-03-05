import 'dart:async';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepo;

  UserService(this._userRepo);

  /// Retorna a stream de usuários do sistema
  Stream<List<User>> getUsersStream() {
    return _userRepo.getUsersStream();
  }

  /// Salva ou atualiza os dados de um usuário
  Future<void> saveUserData(User user) async {
    // Aqui no futuro pode entrar lógicas como "Validar se e-mail mudou" 
    // ou "Garantir que não remova privilégios do único admin"
    return _userRepo.saveUserData(user);
  }

  /// Ativa ou desativa um usuário (Soft Delete)
  Future<void> toggleUserStatus(String userId, bool newStatus) async {
    return _userRepo.toggleUserStatus(userId, newStatus);
  }
}
