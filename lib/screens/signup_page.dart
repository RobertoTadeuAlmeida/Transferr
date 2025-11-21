import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Controller para confirmar a senha
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // MÉTODO PARA CRIAR A CONTA DO USUÁRIO
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // MÉTODO PARA MOSTRAR MENSAGENS DE ERRO CLARAS
  void _handleAuthError(dynamic error) {
    String errorMessage = 'Ocorreu um erro desconhecido.';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          errorMessage = 'Este e-mail já está em uso por outra conta.';
          break;
        case 'weak-password':
          errorMessage = 'A senha é muito fraca. Tente uma mais forte.';
          break;
        case 'invalid-email':
          errorMessage = 'O formato do e-mail fornecido é inválido.';
          break;
        default:
          errorMessage = 'Ocorreu um erro ao criar a conta. Tente novamente.';
      }
    } else {
      errorMessage = error.toString();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crie sua conta no Transferr',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de E-mail
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Por favor, digite seu e-mail.';
                    if (!value.contains('@') || !value.contains('.'))
                      return 'Digite um e-mail válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Senha
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Por favor, digite sua senha.';
                    if (value.length < 6)
                      return 'A senha deve ter no mínimo 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Confirmar Senha
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_person_outlined),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Por favor, confirme sua senha.';
                    if (value != _passwordController.text)
                      return 'As senhas não coincidem.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botão de Criar Conta
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _createAccount,
                        child: const Text('Criar Conta'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
