import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Função para navegar e fechar o drawer, usando pushReplacementNamed
    // para evitar empilhar telas principais (Home, Clientes, etc.)
    void navigateTo(String routeName) {
      // Pega a rota atual para evitar navegar para a mesma tela
      final currentRoute = ModalRoute.of(context)?.settings.name;
      Navigator.pop(context); // Fecha o drawer primeiro
      if (currentRoute != routeName) {
        Navigator.pushReplacementNamed(context, routeName);
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF97316)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Usuário',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? 'Não autenticado',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // --- Itens do Menu ---
          ListTile(
            leading: const Icon(Icons.star, color: Colors.white),
            title: const Text('Destaques', style: TextStyle(color: Colors.white)),
            onTap: () => navigateTo('/'),
          ),
          ListTile(
            leading: const Icon(Icons.tour, color: Colors.white),
            title: const Text('Todas as Excursões', style: TextStyle(color: Colors.white)),
            onTap: () => navigateTo('/excursions'),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text('Passageiros', style: TextStyle(color: Colors.white)),
            onTap: () => navigateTo('/clients'),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.white),
            title: const Text('Finanças', style: TextStyle(color: Colors.white)),
            onTap: () => navigateTo('/finance'),
          ),
          const Divider(color: Colors.white38),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Configurações', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              // Usa pushNamed para colocar a tela de config por cima
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // O AuthWrapper cuidará da navegação após o logout
            },
          ),
        ],
      ),
    );
  }
}
