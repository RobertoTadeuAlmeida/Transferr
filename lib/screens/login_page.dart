// lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transferr/screens/signup_page.dart'; // Garanta que este import está aqui

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // MÉTODO PARA LOGIN COM EMAIL E SENHA
  Future<void> _signInWithEmail() async {
    // 1. Valida se os campos de e-mail e senha estão preenchidos corretamente
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Tenta fazer o login usando o serviço de autenticação do Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), // Garante que não há espaços extras
        password: _passwordController.text.trim(),
      );
      // Se o login for bem-sucedido, o AuthWrapper cuidará do resto.

    } catch (e) {
      // 3. Se houver um erro, chama a função padronizada para mostrar a mensagem
      _handleAuthError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // MÉTODO PADRONIZADO PARA LIDAR COM ERROS (igual ao da SignUpPage)
  void _handleAuthError(dynamic error) {
    String errorMessage = 'Ocorreu um erro desconhecido.';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'Nenhum usuário encontrado com este e-mail.';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta. Por favor, tente novamente.';
          break;
        case 'invalid-email':
          errorMessage = 'O formato do e-mail fornecido é inválido.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta conta de usuário foi desativada.';
          break;
      // O erro que você recebeu se encaixa aqui:
        case 'invalid-credential':
          errorMessage = 'Credenciais incorretas. Verifique o e-mail e a senha.';
          break;
        default:
          errorMessage = 'Ocorreu um erro de autenticação. Tente mais tarde.';
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
    // A UI permanece a mesma, mas agora se conecta à lógica corrigida
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
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
                  'Bem-vindo ao Transferr',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse sua conta para continuar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // Campo de E-mail
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Por favor, digite seu e-mail.';
                    if (!value.contains('@') || !value.contains('.')) return 'Digite um e-mail válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Senha
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor, digite sua senha.';
                    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botão de Entrar
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _signInWithEmail,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 24),

                // Link para Criar Conta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem uma conta?', style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Cadastre-se'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
