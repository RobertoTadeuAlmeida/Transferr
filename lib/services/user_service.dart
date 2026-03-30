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

  /// Verifica se um documento (CPF/RG) já está cadastrado para outro usuário.
  Future<bool> isDocumentUnique(String document, String currentUserId) async {
    if (document.isEmpty) return true;
    
    final existingUser = await _userRepo.getUserByDocument(document);
    
    if (existingUser != null && existingUser.id != currentUserId) {
      throw "Documento já cadastrado para outro usuário.";
    }
    
    return true;
  }

  /// Salva ou atualiza os dados do usuário com validações rigorosas.
  Future<void> saveUserData(User user) async {
    // 1. Validação de integridade do modelo (Regras de formato, campos obrigatórios, etc)
    UserValidator.validate(user);

    // 2. Validação de unicidade no banco de dados (Regra de Negócio)
    await isDocumentUnique(user.document, user.id);

    // 3. Sanitização final para persistência
    final sanitizedUser = user.copyWith(
      name: user.name.trim(),
      email: user.email.toLowerCase().trim(),
      companyName: user.companyName.isEmpty ? "Aguardando Vínculo" : user.companyName.trim(),
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

  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    await _userRepo.respondToInvite(inviteId, status);
    
    if (status == 'aceito') {
      final Set<String> updatedCompanies = Set<String>.from(currentUser.companies)
        ..add(companyId)
        ;

      final Map<String, String> updatedRoles = Map.from(currentUser.roles);
      updatedRoles[companyId] = 'AGENTE';
      
      String newActiveCompany = currentUser.company;
      if (newActiveCompany.isEmpty) {
        newActiveCompany = companyId;
      }
      
      final updatedUser = currentUser.copyWith(
        company: newActiveCompany, 
        companies: updatedCompanies.toList(),
        roles: updatedRoles,
        isActive: true,
      );
      
      await saveUserData(updatedUser);
    }
  }
}
