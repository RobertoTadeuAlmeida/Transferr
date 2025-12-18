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

  /// Carrega a versão do app a partir do pubspec.yaml
  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Versão ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  /// Executa o logout do usuário no Firebase Auth
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Após o logout, o AuthWrapper (ou sua tela de login) assumirá o controle.
      // É uma boa prática navegar para a rota raiz e remover todas as outras.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Seção Conta ---
          const Text(
            'Conta',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair (Logout)'),
            subtitle: const Text('Desconectar sua conta deste dispositivo'),
            onTap: () {
              // Mostra um diálogo de confirmação antes de sair
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
                        child: const Text('Sair', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Fecha o diálogo
                          _logout(); // Executa o logout
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
          const Text(
            'Sobre o App',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versão do Aplicativo'),
            subtitle: Text(_appVersion), // Mostra a versão carregada
          ),
        ],
      ),
    );
  }
}
