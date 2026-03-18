import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/screens/home_page.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';
import 'pending_company_page.dart'; // Import da nova tela de transição

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. ESTADO DE ERRO CRÍTICO
    if (authProvider.errorMessage != null && authProvider.currentUser == null) {
      return _buildErrorScreen(context, authProvider);
    }

    // 2. ESTADO DE CARREGAMENTO (Sincronizando com o Firestore)
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Sincronizando sua conta...',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // 3. LOGADO: Verificando Contexto de Empresa
    final user = authProvider.currentUser;
    if (user != null) {
      
      // Verificação de conta desativada globalmente
      if (!user.isActive) {
        return _buildInactiveAccountScreen(context, authProvider);
      }

      // NOVO FLUXO SAAS: 
      // Se o usuário logou mas não tem empresa vinculada, ele vai para a tela de transição.
      if (user.hasNoCompany) {
        return const PendingCompanyPage();
      }

      // Se já possui empresa, vai para a Home.
      return const HomePage();
    }

    // 4. NÃO AUTENTICADO
    return const LoginPage();
  }

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
                onPressed: () => auth.logout(), 
                icon: const Icon(Icons.login),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'Sua conta está inativa no momento. Por favor, entre em contato com o suporte.',
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
