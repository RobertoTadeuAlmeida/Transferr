import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:transferr/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Função para navegar e fechar o drawer
    void navigateTo(String routeName) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      Navigator.pop(context); // Fecha o drawer primeiro
      if (currentRoute != routeName) {
        Navigator.pushReplacementNamed(context, routeName);
      }
    }

    return Drawer(
      // 1. A cor do Drawer já é definida pelo drawerTheme
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            // 2. A cor do Header usa a cor primária do tema
            decoration: BoxDecoration(color: theme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 3. Os textos agora usam o textTheme
                Text(
                  currentUser?.displayName ??
                      currentUser?.email?.split('@').first ??
                      'Usuário',
                  style: textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'Não autenticado',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // --- Itens do Menu ---
          // 4. Os ListTiles agora são 100% controlados pelo listTileTheme
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Destaques'),
            onTap: () => navigateTo('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.tour_outlined),
            title: const Text('Todas as Excursões'),
            onTap: () => navigateTo('/excursions'),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Passageiros'),
            onTap: () => navigateTo('/global-passengers'),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Finanças'),
            onTap: () => navigateTo('/finance'),
          ),
          const Divider(), // O Divider usa a cor padrão do tema
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            // 5. Ícone e texto da ação "Sair" usam a cor de erro do tema
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              Navigator.pop(context); // Fecha o drawer
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Sair da conta?'),
                    content: const Text(
                      'Você precisará informar seu e-mail e senha novamente para acessar.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Cancela
                        child: const Text('CANCELAR'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed: () async {
                          // Fecha o diálogo
                          Navigator.pop(context);

                          // 3. Usa o AuthProvider para deslogar (mais seguro que direto no Firebase)

                          try {
                            await context.read<AuthProvider>().logout();
                            // O AuthWrapper cuidará de levar o usuário para a LoginPage automaticamente
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro ao sair da conta.'),
                              ),
                            );
                          }
                        },
                        child: const Text('SAIR'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
