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

  /// Salva dados do usuário com sanitização básica
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

  // ===========================================================================
  // REGRAS DE NEGÓCIO: GESTÃO DE EQUIPE
  // ===========================================================================

  /// Altera o status de um operador. 
  /// Segurança: Só deve ser permitido se o Admin pertencer à mesma empresa.
  Future<void> toggleUserStatus(String targetUserId, bool newStatus) async {
    if (targetUserId.isEmpty) throw Exception("ID do usuário inválido.");
    return _userRepo.toggleUserStatus(targetUserId, newStatus);
  }

  // ===========================================================================
  // REGRAS DE NEGÓCIO: SISTEMA DE CONVITES
  // ===========================================================================

  /// Envia um convite com validações de segurança
  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserId,
    required String currentUserId,
  }) async {
    // 1. Regra: Não pode convidar a si mesmo
    if (toUserId == currentUserId) {
      throw Exception("Você não pode enviar um convite para si mesmo.");
    }

    // 2. Regra: Verificar se o usuário já existe e se já está na empresa
    final targetUser = await _userRepo.getUserData(toUserId);
    if (targetUser == null) {
      throw Exception("Usuário destino não encontrado.");
    }

    if (targetUser.companies.contains(fromCompanyId)) {
      throw Exception("Este usuário já faz parte da sua equipe.");
    }

    // 3. Regra: Evitar convites duplicados pendentes (opcional, mas recomendado)
    // Aqui poderíamos consultar a coleção de convites para ver se já existe um 'pendente'

    return _userRepo.sendInvite(
      fromCompanyId: fromCompanyId,
      fromCompanyName: fromCompanyName,
      toUserId: toUserId,
    );
  }

  /// Escuta convites pendentes
  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _userRepo.getPendingInvites(userId);
  }

  /// Responde ao convite com validação de vínculo
  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    // 1. Atualiza o status do convite (aceito/recusado)
    await _userRepo.respondToInvite(inviteId, status);
    
    if (status == 'aceito') {
      // 2. Regra: Ao aceitar, adicionamos a empresa à lista de empresas do usuário
      final List<String> updatedCompanies = List.from(currentUser.companies);
      
      if (!updatedCompanies.contains(companyId)) {
        updatedCompanies.add(companyId);
      }
      
      // 3. Define a nova empresa como a ATIVA no momento do aceite
      final updatedUser = currentUser.copyWith(
        company: companyId, 
        companies: updatedCompanies,
        isActive: true,
      );
      
      await _userRepo.saveUserData(updatedUser);
    }
  }
}
