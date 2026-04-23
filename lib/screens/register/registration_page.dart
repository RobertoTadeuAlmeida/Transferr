import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'widgets/personal_info_step.dart';
import 'widgets/address_step.dart';
import 'widgets/credentials_step.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  String _selectedProfile = 'ADMIN';

  final Map<String, TextEditingController> _controllers = {
    'company': TextEditingController(),
    'document': TextEditingController(),
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'zipCode': TextEditingController(),
    'state': TextEditingController(),
    'city': TextEditingController(),
    'address': TextEditingController(),
    'neighborhood': TextEditingController(),
    'number': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _nextPage() async {
    final provider = context.read<AuthProvider>();

    // Validação básica do formulário atual
    if (!_validateCurrentStep()) {
      _showErrorSnackBar("Por favor, preencha os campos obrigatórios corretamente.");
      return;
    }

    // Validação Extra: Se estiver no passo 1, validar documento no Firebase antes de avançar
    if (_currentStep == 0) {
      final String doc = _controllers['document']!.text;
      
      // Validação assíncrona de unicidade
      final String? error = await provider.validateDocument(doc);
      if (error != null) {
        _showErrorSnackBar(error);
        return; // BLOQUEIA O AVANÇO
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _handleFinalSubmit();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) return _formKey1.currentState?.validate() ?? false;
    if (_currentStep == 1) return _formKey2.currentState?.validate() ?? false;
    if (_currentStep == 2) return _formKey3.currentState?.validate() ?? false;
    return false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor, // Cor de atenção amigável
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleFinalSubmit() async {
    final provider = context.read<AuthProvider>();

    final user = User(
      id: '',
      company: '', 
      companyName: _controllers['company']!.text.trim(),
      companies: [],
      roles: {},
      name: _controllers['name']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      phone: _controllers['phone']!.text,
      document: _controllers['document']!.text,
      birthDate: DateTime.now(),
      profile: _selectedProfile,
      zipCode: _controllers['zipCode']!.text,
      address: _controllers['address']!.text,
      number: _controllers['number']!.text,
      neighborhood: _controllers['neighborhood']!.text,
      city: _controllers['city']!.text,
      state: _controllers['state']!.text,
      createdAt: DateTime.now(),
    );

    try {
      await provider.register(user, _controllers['password']!.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bem-vindo à Transferr! Cadastro realizado.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Passo ${_currentStep + 1} de 3"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousPage,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.primaryColor.withAlpha(25),
            minHeight: 6,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PersonalInfoStep(
                  formKey: _formKey1,
                  controllers: _controllers,
                  selectedProfile: _selectedProfile,
                  onProfileChanged: (val) => setState(() => _selectedProfile = val!),
                ),
                AddressStep(formKey: _formKey2, controllers: _controllers),
                CredentialsStep(formKey: _formKey3, controllers: _controllers),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _currentStep == 2 ? "FINALIZAR CADASTRO" : "PRÓXIMO",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
