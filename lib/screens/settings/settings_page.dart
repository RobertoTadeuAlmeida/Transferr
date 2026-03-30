import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/widgets/app_drawer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'Versão ${packageInfo.version} (build ${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Não foi possível carregar a versão';
        });
      }
    }
  }

  Future<void> _logout() async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    try {
      // CORREÇÃO: Usar o AuthProvider em vez do FirebaseAuth direto
      await context.read<AuthProvider>().logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'CONTA'),
          const Divider(height: 16, color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair (Logout)'),
            subtitle: const Text('Desconectar sua conta deste dispositivo'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirmar Saída'),
                    content: const Text('Tem certeza que deseja sair da sua conta?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Sair'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _logout();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
          _buildSectionTitle(context, 'SOBRE O APP'),
          const Divider(height: 16, color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão do Aplicativo'),
            subtitle: Text(_appVersion),
          ),
        ],
      ),
    );
  }
}
