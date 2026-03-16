import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. O Provider realiza o login
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),

      );
      debugPrint('Login realizado com sucesso!');

      // 2. SE CHEGOU AQUI, O LOGIN FOI SUCESSO.
      // Se você usa AuthWrapper no main.dart, ele detectará a mudança
      // e trocará a tela sozinho. Se NÃO usa, descomente a linha abaixo:
      // if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // REMOVIDO: navigator.pushReplacementNamed('/home') daqui!

      String message = 'Erro ao entrar.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'E-mail ou senha incorretos.';
      } else if (e.code == 'user-disabled') {
        message = 'Esta conta foi desativada.';
      } else if (e.code == 'too-many-requests') {
        message = 'Muitas tentativas. Tente novamente mais tarde.';
      }

      _showError(messenger, message);
    } catch (e) {
      if (!mounted) return;
      _showError(messenger, 'Erro inesperado. Verifique sua conexão.');
    }
  }

  void _showError(ScaffoldMessengerState messenger, String message) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Observa o estado de carregamento do provider
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.directions_bus_filled_rounded,
                      size: 80, color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Transferr',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe seu e-mail';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                                () => _isPasswordObscured = !_isPasswordObscured),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Senha curta'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ENTRAR'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Cadastre sua Empresa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}