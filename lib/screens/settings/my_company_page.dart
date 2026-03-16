import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme/app_theme.dart';

class MyCompanyPage extends StatelessWidget {
  const MyCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Lista de IDs de empresas vinculadas (evitando duplicatas)
    final companies = user.companies.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Atuação'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentCompanyHeader(user, theme),
            const SizedBox(height: 32),
            Text(
              "ALTERAR EMPRESA DE ATUAÇÃO",
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (companies.length <= 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Você está vinculado a apenas uma empresa no momento.",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final companyId = companies[index];
                  final isCurrent = companyId == user.company;

                  return _CompanyTile(
                    companyId: companyId,
                    isCurrent: isCurrent,
                    onTap: isCurrent 
                        ? null 
                        : () => _handleCompanySwitch(context, companyId),
                  );
                },
              ),
            
            const SizedBox(height: 40),
            _buildInfoSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCompanyHeader(dynamic user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.business, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Empresa Ativa",
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.companyName.isEmpty ? "Empresa sem nome" : user.companyName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${user.company}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Ao trocar de empresa, suas excursões, passageiros e dados financeiros serão filtrados para o novo contexto selecionado.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompanySwitch(BuildContext context, String companyId) async {
    final auth = context.read<AuthProvider>();
    final excursions = context.read<ExcursionProvider>();
    final users = context.read<UserProvider>();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Troca a empresa no Auth (Firebase + Local)
      await auth.switchCompany(companyId);

      // 2. Notifica o ExcursionProvider para trocar o Stream de viagens
      excursions.listenToExcursions(companyId);

      // 3. Notifica o UserProvider para trocar o Stream da equipe
      users.initCompanyStream(companyId);

      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Empresa de atuação alterada com sucesso!"),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao trocar empresa: $e"), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _CompanyTile extends StatelessWidget {
  final String companyId;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _CompanyTile({
    required this.companyId,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrent ? AppTheme.successColor : Colors.white10,
            width: isCurrent ? 2 : 1,
          ),
        ),
        tileColor: isCurrent 
            ? AppTheme.successColor.withValues(alpha: 0.05) 
            : AppTheme.cardColor,
        leading: Icon(
          Icons.business, 
          color: isCurrent ? AppTheme.successColor : Colors.white38
        ),
        title: Text(
          isCurrent ? "Atuando Agora" : "Mudar para esta empresa",
          style: TextStyle(
            color: isCurrent ? AppTheme.successColor : Colors.white,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          "ID: $companyId",
          style: const TextStyle(color: Colors.white24, fontSize: 11),
        ),
        trailing: isCurrent 
            ? const Icon(Icons.check_circle, color: AppTheme.successColor)
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
      ),
    );
  }
}
