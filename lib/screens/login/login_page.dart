import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transferr/screens/signup_page.dart';

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
  // Para controlar a visibilidade da senha
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // O AuthWrapper cuidará da navegação em caso de sucesso.
    } catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthError(dynamic error) {
    String errorMessage = 'Ocorreu um erro desconhecido.';

    if (error is FirebaseAuthException) {
      errorMessage = switch (error.code) {
        'user-not-found' => 'Nenhum usuário encontrado com este e-mail.',
        'wrong-password' => 'Senha incorreta. Por favor, tente novamente.',
        'invalid-email' => 'O formato do e-mail fornecido é inválido.',
        'user-disabled' => 'Esta conta de usuário foi desativada.',
        'invalid-credential' => 'Credenciais incorretas. Verifique o e-mail e a senha.',
        _ => 'Ocorreu um erro de autenticação. Tente mais tarde.',
      };
    } else {
      errorMessage = error.toString();
    }

    if (mounted) {
      // 1. SnackBar usa o tema para a cor de fundo e estilo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // O AppBar já é estilizado pelo tema
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
                // Os textos já estão usando o tema corretamente
                Text(
                  'Bem-vindo de volta!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse sua conta para continuar',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // 2. TextFormField agora usa 100% do inputDecorationTheme
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Por favor, digite seu e-mail.';
                    if (!value.contains('@') || !value.contains('.')) return 'Digite um e-mail válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    // Adiciona um ícone para mostrar/ocultar a senha
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor, digite sua senha.';
                    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 3. O botão de Entrar não precisa mais de estilo local
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _signInWithEmail,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Não tem uma conta?', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    // 4. O TextButton agora usa a cor primária do tema
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
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
