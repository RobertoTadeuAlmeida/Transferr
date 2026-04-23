import 'dart:async';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../validators/user_validator.dart';

class UserService {
  final UserRepository _userRepo;

  UserService(this._userRepo);

  Stream<List<User>> getUsersStream(String companyId) {
    if (companyId.isEmpty) return Stream.value([]);
    return _userRepo.getUsersStream(companyId);
  }

  /// Verifica se o documento é único no sistema usando a nova coleção de índice.
  /// Retorna null se for válido/único, ou uma mensagem de erro se já existir em outra conta.
  Future<String?> validateDocumentUniqueness(String document, String currentUserId) async {
    final cleanDoc = document.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDoc.isEmpty) return null;
    
    try {
      final String indexId = 'doc_$cleanDoc';
      final String? ownerUid = await _userRepo.getOwnerUidFromIndex(indexId);
      
      if (ownerUid != null && ownerUid != currentUserId) {
        return "Este CPF/CNPJ já está cadastrado em outra conta.";
      }
      return null;
    } catch (e) {
      // Se der erro de permissão aqui, é porque as regras ainda não permitem get público no index.
      return "Erro ao validar documento. Tente novamente.";
    }
  }

  /// Verifica se o email é único usando a coleção de índice.
  Future<String?> validateEmailUniqueness(String email, String currentUserId) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    
    try {
      final String indexId = 'email_$cleanEmail';
      final String? ownerUid = await _userRepo.getOwnerUidFromIndex(indexId);
      
      if (ownerUid != null && ownerUid != currentUserId) {
        return "Este e-mail já está em uso por outro usuário.";
      }
      return null;
    } catch (e) {
      return "Erro ao validar e-mail. Tente novamente.";
    }
  }

  Future<void> saveUserData(User user) async {
    UserValidator.validate(user);
    
    // 1. Validação de unicidade de documento
    final docError = await validateDocumentUniqueness(user.document, user.id);
    if (docError != null) throw docError;

    // 2. Validação de unicidade de email
    final emailError = await validateEmailUniqueness(user.email, user.id);
    if (emailError != null) throw emailError;

    // 3. Sanitização final
    final sanitizedUser = user.copyWith(
      name: user.name.trim(),
      email: user.email.toLowerCase().trim(),
      companyName: user.companyName.isEmpty ? "Aguardando Vínculo" : user.companyName.trim(),
    );

    // 4. Gravação Atômica (Perfil + Índices)
    return _userRepo.saveUserDataWithIndex(sanitizedUser);
  }

  Future<User?> findUserByEmail(String email) async {
    if (email.isEmpty) return null;
    return _userRepo.getUserByEmail(email);
  }

  Future<void> toggleUserStatus(String targetUserId, bool newStatus) async {
    if (targetUserId.isEmpty) throw Exception("ID do usuário inválido.");
    return _userRepo.updateUserField(targetUserId, 'isActive', newStatus);
  }

  // ===========================================================================
  // REGRAS DE NEGÓCIO: MULTI-TENANT E GESTÃO DE EQUIPE
  // ===========================================================================

  Future<void> updateMemberRole({
    required User operator,
    required String targetUserId,
    required String companyId,
    required String newRole,
  }) async {
    final roleOperator = operator.roles[companyId]?.toUpperCase();
    if (roleOperator != 'ADMIN' && roleOperator != 'OWNER') {
      throw "Acesso negado: Apenas administradores podem alterar papéis.";
    }

    final targetUser = await _userRepo.getUserData(targetUserId);
    if (targetUser == null) throw "Usuário não encontrado.";

    if (targetUser.roles[companyId]?.toUpperCase() == 'OWNER') {
      throw "Acesso negado: O proprietário da empresa não pode ter seu papel alterado.";
    }

    final Map<String, String> updatedRoles = Map.from(targetUser.roles);
    updatedRoles[companyId] = newRole.toUpperCase();

    String updatedProfile = targetUser.profile;
    if (targetUser.company == companyId) {
      updatedProfile = newRole.toUpperCase();
    }

    await saveUserData(targetUser.copyWith(
      roles: updatedRoles,
      profile: updatedProfile,
    ));
  }

  Future<void> removeMemberFromCompany({
    required User operator,
    required String targetUserId,
    required String companyId,
  }) async {
    final roleOperator = operator.roles[companyId]?.toUpperCase();
    if (roleOperator != 'ADMIN' && roleOperator != 'OWNER') {
      throw "Acesso negado: Apenas administradores podem remover membros.";
    }

    final targetUser = await _userRepo.getUserData(targetUserId);
    if (targetUser == null) throw "Usuário não encontrado.";

    if (targetUser.roles[companyId]?.toUpperCase() == 'OWNER') {
      throw "Acesso negado: O proprietário da empresa não pode ser removido.";
    }

    final List<String> updatedCompanies = List.from(targetUser.companies)..remove(companyId);
    final Map<String, String> updatedRoles = Map.from(targetUser.roles)..remove(companyId);

    String newCompany = targetUser.company;
    String newCompanyName = targetUser.companyName;
    
    if (targetUser.company == companyId) {
      if (updatedCompanies.isNotEmpty) {
        newCompany = updatedCompanies.first;
        newCompanyName = await _userRepo.getCompanyName(newCompany);
      } else {
        newCompany = '';
        newCompanyName = 'Aguardando Vínculo';
      }
    }

    await saveUserData(targetUser.copyWith(
      company: newCompany,
      companyName: newCompanyName,
      companies: updatedCompanies,
      roles: updatedRoles,
    ));
  }

  Future<void> transferOwnership({
    required User currentOwner,
    required String targetUserId,
    required String companyId,
  }) async {
    if (currentOwner.roles[companyId]?.toUpperCase() != 'OWNER') {
      throw "Acesso negado: Apenas o proprietário atual pode transferir a titularidade.";
    }

    if (currentOwner.id == targetUserId) {
      throw "Você já é o proprietário desta empresa.";
    }

    final targetUser = await _userRepo.getUserData(targetUserId);
    if (targetUser == null) throw "Usuário alvo não encontrado.";

    if (!targetUser.companies.contains(companyId)) {
      throw "O usuário alvo deve fazer parte da empresa para receber a titularidade.";
    }

    final targetRoles = Map<String, String>.from(targetUser.roles);
    targetRoles[companyId] = 'OWNER';
    await saveUserData(targetUser.copyWith(
      roles: targetRoles,
      profile: targetUser.company == companyId ? 'OWNER' : targetUser.profile,
    ));

    final ownerRoles = Map<String, String>.from(currentOwner.roles);
    ownerRoles[companyId] = 'ADMIN';
    await saveUserData(currentOwner.copyWith(
      roles: ownerRoles,
      profile: currentOwner.company == companyId ? 'ADMIN' : currentOwner.profile,
    ));
  }

  // ===========================================================================
  // SISTEMA DE CONVITES
  // ===========================================================================

  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserEmail,
    required String currentUserId,
  }) async {
    final email = toUserEmail.trim().toLowerCase();
    final targetUser = await _userRepo.getUserByEmail(email);
    
    if (targetUser == null) throw Exception("Usuário com este e-mail não encontrado.");
    if (targetUser.id == currentUserId) throw Exception("Você não pode enviar um convite para si mesmo.");
    if (targetUser.companies.contains(fromCompanyId)) throw Exception("Este usuário já faz parte da sua equipe.");

    return _userRepo.sendInvite(
      fromCompanyId: fromCompanyId,
      fromCompanyName: fromCompanyName,
      toUserId: targetUser.id,
    );
  }

  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) => _userRepo.getPendingInvites(userId);

  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    await _userRepo.respondToInvite(inviteId, status);
    
    if (status == 'aceito') {
      final Set<String> updatedCompanies = Set<String>.from(currentUser.companies)..add(companyId);
      final Map<String, String> updatedRoles = Map.from(currentUser.roles);
      updatedRoles[companyId] = 'AGENTE';
      
      String newActiveCompany = currentUser.company;
      if (newActiveCompany.isEmpty) newActiveCompany = companyId;
      
      await saveUserData(currentUser.copyWith(
        company: newActiveCompany, 
        companies: updatedCompanies.toList(),
        roles: updatedRoles,
        isActive: true,
      ));
    }
  }
}
