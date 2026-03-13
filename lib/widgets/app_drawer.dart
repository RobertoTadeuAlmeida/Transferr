import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, user, theme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, Icons.dashboard_outlined, 'Painel de Controle', '/home'),
                _buildMenuItem(context, Icons.tour_outlined, 'Minhas Viagens', '/excursions'),
                _buildMenuItem(context, Icons.people_alt_outlined, 'Passageiros (CRM)', '/global-passengers'),
                _buildMenuItem(context, Icons.badge_outlined, 'Minha Equipe', '/users'),
                _buildMenuItem(context, Icons.monetization_on_outlined, 'Finanças Globais', '/finance'),
                const Divider(),
                _buildMenuItem(context, Icons.settings_outlined, 'Configurações', '/settings'),
              ],
            ),
          ),
          _buildLogoutButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, ThemeData theme) {
    // Lógica 100% segura para evitar RangeError e exibir rótulo correto
    String companyLabel = "Sem Empresa";
    
    if (user != null) {
      if (user.companyName != null && user.companyName.isNotEmpty) {
        companyLabel = user.companyName;
      } else if (user.company != null && user.company.isNotEmpty) {
        final String id = user.company;
        // Só faz substring se o ID for grande o suficiente, caso contrário usa o ID inteiro
        companyLabel = id.length > 8 ? "ID: ${id.substring(0, 8)}..." : "ID: $id";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      color: theme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 35),
              ),
              if (user != null && user.companies.length > 1)
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                  onPressed: () => _showCompanySelector(context),
                  tooltip: "Trocar de Empresa",
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Usuário',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Tag da Empresa Ativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    companyLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }

  void _showCompanySelector(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final companies = auth.currentUser?.companies ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Selecione a Empresa Ativa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 0),
            ...companies.map((compId) {
              final isCurrent = compId == auth.currentUser?.company;
              return ListTile(
                leading: Icon(Icons.business, color: isCurrent ? Colors.green : null),
                title: Text("Empresa ID: $compId"),
                onTap: isCurrent ? null : () async {
                  await auth.switchCompany(compId);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Sair do App?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NÃO")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM")),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await context.read<AuthProvider>().logout();
            Navigator.pushReplacementNamed(context, '/');
          }
        },
      ),
    );
  }
}
