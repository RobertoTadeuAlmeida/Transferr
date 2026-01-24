import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/registration_repository.dart';

class RegistrationProvider with ChangeNotifier {
  final RegistrationRepository _repository = RegistrationRepository();

  int _pageIndex = 0;

  int get pageIndex => _pageIndex;

  // Step 1: Empresa & Dados Pessoais
  final companyController = TextEditingController();
  final nameController = TextEditingController();
  final documentController = TextEditingController(); // CPF
  final phoneController = TextEditingController();
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _selectedProfile = 'ADMIN';

  String get selectedProfile => _selectedProfile;

  DateTime get birthDate => _birthDate;

  // Step 2: Endereço
  final zipCodeController = TextEditingController();
  final addressController = TextEditingController();
  final numberController = TextEditingController();
  final neighborhoodController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  // Step 3: Credenciais
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // --- SETTERS ---

  void setPageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }

  void setBirthDate(DateTime date) {
    _birthDate = date;
    notifyListeners();
  }

  void nextPage() {
    if (_pageIndex < 2) {
      _pageIndex++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_pageIndex > 0) {
      _pageIndex--;
      notifyListeners();
    }
  }

  void setSelectedProfile(String? profile) {
    if (profile != null) {
      _selectedProfile = profile;
      notifyListeners();
    }
  }

  // --- LÓGICA DE REGISTRO ---

  Future<bool> submitRegistration() async {
    // Validação básica de campos vazios antes de tentar o Firebase
    if (!_validateFields()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = User(
        id: '',
        // O ID será preenchido pelo UID do Firebase no Repository
        company: companyController.text.trim(),
        profile: _selectedProfile,
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        phone: _cleanMask(phoneController.text),
        document: _cleanMask(documentController.text),
        birthDate: _birthDate,
        zipCode: _cleanMask(zipCodeController.text),
        address: addressController.text.trim(),
        number: numberController.text.trim(),
        neighborhood: neighborhoodController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim().toUpperCase(),
        createdAt: DateTime.now(),
      );

      // Chamada ao repositório
      await _repository.signUp(
        user: newUser,
        password: passwordController.text.trim(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- AUXILIARES ---

  bool _validateFields() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _errorMessage = "E-mail e senha são obrigatórios.";
      notifyListeners();
      return false;
    }
    if (passwordController.text.length < 6) {
      _errorMessage = "A senha deve ter pelo menos 6 caracteres.";
      notifyListeners();
      return false;
    }
    return true;
  }

  String _handleError(dynamic e) {
    String error = e.toString();
    if (error.contains('email-already-in-use')) {
      return 'Este e-mail já está cadastrado por outra empresa.';
    } else if (error.contains('invalid-email')) {
      return 'O e-mail digitado não é válido.';
    } else if (error.contains('weak-password')) {
      return 'A senha digitada é muito fraca.';
    } else if (error.contains('permission-denied')) {
      return 'Erro de permissão no banco de dados. Contate o suporte.';
    }
    return error
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }

  String _cleanMask(String text) {
    return text.replaceAll(RegExp(r'[^\d]'), '');
  }

  @override
  void dispose() {
    companyController.dispose();
    nameController.dispose();
    documentController.dispose();
    phoneController.dispose();
    zipCodeController.dispose();
    addressController.dispose();
    numberController.dispose();
    neighborhoodController.dispose();
    cityController.dispose();
    stateController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
