import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) {
        // 1. SnackBar de erro usa o tema
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Widget auxiliar para os títulos de seção
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      // 2. Título da seção usa o tema
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O AppBar já é estilizado pelo tema
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Seção Conta ---
          _buildSectionTitle(context, 'CONTA'),
          const Divider(height: 16, color: Colors.white24),
          ListTile(
            // 3. O ListTile agora é totalmente controlado pelo listTileTheme
            leading: const Icon(Icons.logout),
            title: const Text('Sair (Logout)'),
            subtitle: const Text('Desconectar sua conta deste dispositivo'),
            onTap: () {
              showDialog(
                context: context,
                // 4. O AlertDialog agora é controlado pelo dialogTheme
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirmar Saída'),
                    content: const Text('Tem certeza que deseja sair da sua conta?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      // Botão com a cor de erro do tema
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

          // --- Seção Sobre ---
          _buildSectionTitle(context, 'SOBRE O APP'),
          const Divider(height: 16, color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão do Aplicativo'),
            subtitle: Text(_appVersion),
            onTap: null, // Desabilita o efeito de clique
          ),
        ],
      ),
    );
  }
}
