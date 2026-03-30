import '../models/user.dart';

/// Classe responsável por centralizar as regras de validação de negócio para o modelo User.
/// Segue o princípio da Responsabilidade Única (SRP) para manter o Service limpo.
class UserValidator {
  
  /// Valida a integridade e consistência dos dados do usuário.
  /// Lança uma [Exception] detalhada caso alguma regra de negócio seja violada.
  static void validate(User user) {
    _validateIdentity(user);
    _validateContact(user);
    _validatePersonalData(user);
    _validateAddress(user);
    _validateBusinessRules(user);
  }

  static void _validateIdentity(User user) {
    if (user.id.isEmpty) {
      throw Exception("ID do usuário não pode ser vazio.");
    }
    if (user.name.trim().isEmpty) {
      throw Exception("Nome do usuário não pode ser vazio.");
    }
  }

  static void _validateContact(User user) {
    // Validação de Email
    final email = user.email.trim();
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception("O formato do email é inválido.");
    }

    // Validação de Telefone (apenas dígitos para verificação de tamanho)
    final digitsOnlyPhone = user.phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnlyPhone.length < 10) {
      throw Exception("O número de telefone é inválido (mínimo 10 dígitos).");
    }
  }

  static void _validatePersonalData(User user) {
    if (user.document.trim().isEmpty) {
      throw Exception("O documento (CPF/RG) é obrigatório.");
    }

    if (user.birthDate.isAfter(DateTime.now())) {
      throw Exception("A data de nascimento não pode ser no futuro.");
    }
  }

  static void _validateAddress(User user) {
    final digitsOnlyCep = user.zipCode.replaceAll(RegExp(r'\D'), '');
    if (digitsOnlyCep.length != 8) {
      throw Exception("O formato do CEP é inválido (deve ter 8 dígitos).");
    }
    
    if (user.city.trim().isEmpty || user.state.trim().isEmpty) {
      throw Exception("A localidade (cidade/estado) é obrigatória.");
    }
  }

  static void _validateBusinessRules(User user) {
    // Validação Multi-tenant
    if (user.company.isEmpty) {
      throw Exception("O usuário deve estar vinculado a uma empresa ativa.");
    }
    
    if (!user.companies.contains(user.company)) {
      throw Exception("A empresa ativa deve estar na lista de empresas do usuário.");
    }

    // Validação de Papel (Role)
    final role = (user.roles[user.company] ?? '').toUpperCase();
    if (role != 'ADMIN' && role != 'AGENTE') {
      throw Exception("Papel inválido definido para a empresa ativa.");
    }
  }
}
