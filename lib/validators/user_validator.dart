import '../models/user.dart';

class UserValidator {
  
  static void validate(User user) {
    _validateIdentity(user);
    _validateContact(user);
    _validatePersonalData(user);
    _validateAddress(user);
    _validateBusinessRules(user);
  }

  static void _validateIdentity(User user) {
    if (user.id.isEmpty) throw Exception("ID do usuário não pode ser vazio.");
    if (user.name.trim().isEmpty) throw Exception("Nome do usuário não pode ser vazio.");
  }

  static void _validateContact(User user) {
    final email = user.email.trim();
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception("O formato do email é inválido.");
    }
    final digitsOnlyPhone = user.phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnlyPhone.length < 10) {
      throw Exception("O número de telefone é inválido.");
    }
  }

  static void _validatePersonalData(User user) {
    if (user.document.trim().isEmpty) throw Exception("O documento (CPF/RG) é obrigatório.");
    if (user.birthDate.isAfter(DateTime.now())) throw Exception("Data de nascimento inválida.");
  }

  static void _validateAddress(User user) {
    final digitsOnlyCep = user.zipCode.replaceAll(RegExp(r'\D'), '');
    if (digitsOnlyCep.length != 8) throw Exception("CEP inválido.");
    if (user.city.trim().isEmpty || user.state.trim().isEmpty) throw Exception("Cidade/Estado obrigatórios.");
  }

  static void _validateBusinessRules(User user) {
    // Se o usuário não tem empresa (Aguardando Vínculo), ignoramos validações de role/company
    if (user.company.isEmpty) return;
    
    if (!user.companies.contains(user.company)) {
      throw Exception("A empresa ativa deve estar na lista de empresas do usuário.");
    }

    final role = (user.roles[user.company] ?? '').toUpperCase();
    // ADICIONADO: Suporte ao papel OWNER
    if (role != 'ADMIN' && role != 'AGENTE' && role != 'OWNER') {
      throw Exception("Papel inválido definido para a empresa ativa.");
    }
  }
}
