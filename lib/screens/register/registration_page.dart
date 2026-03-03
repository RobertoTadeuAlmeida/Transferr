import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Form Keys para cada passo
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Perfil selecionado
  String _selectedProfile = 'ADMIN';

  // Controladores centralizados
  final Map<String, TextEditingController> _controllers = {
    'company': TextEditingController(),
    'document': TextEditingController(),
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'zipCode': TextEditingController(),
    'state': TextEditingController(),
    'city': TextEditingController(),
    'address': TextEditingController(),
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

  void _nextPage() {
    if (_validateCurrentStep()) {
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

  Future<void> _handleFinalSubmit() async {
    final provider = context.read<AuthProvider>();

    final user = User(
      id: '',
      company: _controllers['company']!.text,
      name: _controllers['name']!.text,
      email: _controllers['email']!.text,
      phone: _controllers['phone']!.text,
      document: _controllers['document']!.text,
      birthDate: DateTime.now(),
      profile: _selectedProfile,
      zipCode: _controllers['zipCode']!.text,
      address: _controllers['address']!.text,
      number: _controllers['number']!.text,
      neighborhood: '',
      city: _controllers['city']!.text,
      state: _controllers['state']!.text,
      createdAt: DateTime.now(),
    );

    try {
      await provider.register(user, _controllers['password']!.text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _nextPage,
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_currentStep == 2 ? "FINALIZAR" : "PRÓXIMO"),
              ),
            ),
          )
        ],
      ),
    );
  }
}