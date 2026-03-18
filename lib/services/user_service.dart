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

  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserEmail,
    required String currentUserId,
  }) async {
    final email = toUserEmail.trim().toLowerCase();

    final targetUser = await _userRepo.getUserByEmail(email);
    
    if (targetUser == null) {
      throw Exception("Usuário com este e-mail não encontrado no Transferr.");
    }

    if (targetUser.id == currentUserId) {
      throw Exception("Você não pode enviar um convite para si mesmo.");
    }

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

  /// Responde ao convite garantindo a integridade dos múltiplos papéis (Roles)
  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    // 1. Atualiza o status do convite no banco
    await _userRepo.respondToInvite(inviteId, status);
    
    if (status == 'aceito') {
      // 2. Atualiza a lista de empresas vinculadas
      final List<String> updatedCompanies = List.from(currentUser.companies);
      if (!updatedCompanies.contains(companyId)) {
        updatedCompanies.add(companyId);
      }

      // 3. ATUALIZA OS PAPÉIS (ROLES): 
      // Todo usuário convidado entra inicialmente como 'AGENTE' na organização.
      // O Admin da empresa pode promover para 'ADMIN' depois se desejar.
      final Map<String, String> updatedRoles = Map.from(currentUser.roles);
      updatedRoles[companyId] = 'AGENTE';
      
      // 4. Se o usuário não tiver NENHUMA empresa ativa (recém cadastrado), 
      // definimos esta como a padrão.
      String newActiveCompany = currentUser.company;
      if (newActiveCompany.isEmpty) {
        newActiveCompany = companyId;
      }
      
      final updatedUser = currentUser.copyWith(
        company: newActiveCompany, 
        companies: updatedCompanies,
        roles: updatedRoles,
        isActive: true,
      );
      
      await _userRepo.saveUserData(updatedUser);
    }
  }
}
