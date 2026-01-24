import 'package:flutter/material.dart';
import 'package:provider/provider.dart';import '../providers/auth_provider.dart';
import 'login/login_page.dart';
import 'excursions/excursions_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. ESTADO DE ERRO (O MAIS IMPORTANTE PARA O SEU PROBLEMA)
    // Se o login no Auth funcionou, mas houve erro ao buscar os dados no Firestore
    if (authProvider.errorMessage != null && authProvider.currentUser == null) {
      return _buildErrorScreen(context, authProvider);
    }

    // 2. ESTADO DE CARREGAMENTO
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Sincronizando sua conta...',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // 3. USUÁRIO AUTENTICADO
    if (authProvider.currentUser != null) {
      // Verificação de conta ativa
      if (!authProvider.currentUser!.isActive) {
        return _buildInactiveAccountScreen(context, authProvider);
      }

      // Se tudo estiver OK, vai para a página inicial (Excursions ou Home)
      return const ExcursionsPage();
    }

    // 4. NÃO AUTENTICADO
    return const LoginPage();
  }

  /// Tela para erros críticos (Ex: Falha de conexão, erro de permissão no Firestore)
  Widget _buildErrorScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              auth.errorMessage ?? 'Não foi possível carregar seus dados de acesso.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => auth.logout(), // Limpa o estado e volta ao login
                icon: const Icon(Icons.login),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tela para contas desativadas
  Widget _buildInactiveAccountScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'Acesso Restrito',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sua conta está inativa no momento. Por favor, entre em contato com o administrador do sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => auth.logout(),
              child: const Text('SAIR DA CONTA'),
            ),
          ],
        ),
      ),
    );
  }
}