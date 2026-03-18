import 'dart:async';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepo;

  UserService(this._userRepo);

  Stream<List<User>> getUsersStream(String companyId) {
    if (companyId.isEmpty) return Stream.value([]);
    return _userRepo.getUsersStream(companyId);
  }

  Future<void> saveUserData(User user) async {
    final sanitizedUser = user.copyWith(
      name: user.name.trim(),
      email: user.email.toLowerCase().trim(),
    );
    return _userRepo.saveUserData(sanitizedUser);
  }

  Future<User?> findUserByEmail(String email) async {
    if (email.isEmpty) return null;
    return _userRepo.getUserByEmail(email);
  }

  Future<void> toggleUserStatus(String targetUserId, bool newStatus) async {
    if (targetUserId.isEmpty) throw Exception("ID do usuário inválido.");
    return _userRepo.toggleUserStatus(targetUserId, newStatus);
  }

  // ===========================================================================
  // REGRAS DE NEGÓCIO: SISTEMA DE CONVITES
  // ===========================================================================

  /// Envia um convite buscando pelo E-MAIL (Mais seguro e evita PERMISSION_DENIED de ID)
  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserEmail,
    required String currentUserId,
  }) async {
    final email = toUserEmail.trim().toLowerCase();

    // 1. Regra: Buscar usuário pelo e-mail
    final targetUser = await _userRepo.getUserByEmail(email);
    
    if (targetUser == null) {
      throw Exception("Usuário com este e-mail não encontrado no Transferr.");
    }

    // 2. Regra: Não pode convidar a si mesmo
    if (targetUser.id == currentUserId) {
      throw Exception("Você não pode enviar um convite para si mesmo.");
    }

    // 3. Regra: Verificar se já está na equipe
    if (targetUser.companies.contains(fromCompanyId)) {
      throw Exception("Este usuário já faz parte da sua equipe.");
    }

    return _userRepo.sendInvite(
      fromCompanyId: fromCompanyId,
      fromCompanyName: fromCompanyName,
      toUserId: targetUser.id,
    );
  }

  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _userRepo.getPendingInvites(userId);
  }

  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    await _userRepo.respondToInvite(inviteId, status);
    
    if (status == 'aceito') {
      final List<String> updatedCompanies = List.from(currentUser.companies);
      
      if (!updatedCompanies.contains(companyId)) {
        updatedCompanies.add(companyId);
      }
      
      final updatedUser = currentUser.copyWith(
        company: companyId, 
        companies: updatedCompanies,
        isActive: true,
      );
      
      await _userRepo.saveUserData(updatedUser);
    }
  }
}
