import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos select para reconstruir apenas se o currentUser mudar
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isAdmin = authProvider.isAdmin;

    return Drawer(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? "U",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            accountName: Text(
              user?.name ?? "Usuário",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ""),
          ),
          
          _DrawerItem(
            icon: Icons.directions_bus_outlined,
            label: 'Minhas Excursões',
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          _DrawerItem(
            icon: Icons.people_outline,
            label: 'Base de Passageiros',
            onTap: () => Navigator.pushReplacementNamed(context, '/global-passengers'),
          ),

          // Itens visíveis apenas para Administradores ou Donos
          if (isAdmin) ...[
            const Divider(color: Colors.white10, height: 32),
            _DrawerItem(
              icon: Icons.analytics_outlined,
              label: 'Financeiro Geral',
              onTap: () => Navigator.pushReplacementNamed(context, '/finance'),
            ),
            _DrawerItem(
              icon: Icons.business_outlined,
              label: 'Minha Empresa',
              onTap: () => Navigator.pushNamed(context, '/my-company'),
            ),
            _DrawerItem(
              icon: Icons.group_add_outlined,
              label: 'Gestão de Equipe',
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),
          ],

          const Spacer(),
          
          const Divider(color: Colors.white10),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Sair do Aplicativo',
            color: AppTheme.errorColor,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = color == AppTheme.errorColor;

    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 14,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
