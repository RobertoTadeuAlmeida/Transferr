import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/excursion.dart';
import '../providers/excursion_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transferr/screens/excursions_page.dart';
import 'package:transferr/screens/clients_list_page.dart';
import 'package:transferr/screens/finance_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    // Usa o getter para obter apenas as excursões em destaque
    final List<Excursion> featuredExcursions = excursionProvider.featuredExcursions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destaques'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      // O Drawer agora chama o método que contém a versão completa
      drawer: _buildAppDrawer(context),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
          : _buildFeaturedList(context, featuredExcursions),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ExcursionsPage()));
        },
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        tooltip: 'Ver Todas as Excursões',
        child: const Icon(Icons.tour),
      ),
    );
  }

  /// Constrói a lista de excursões em destaque ou uma mensagem de "nenhum destaque".
  Widget _buildFeaturedList(BuildContext context, List<Excursion> featuredExcursions) {
    if (featuredExcursions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nenhuma excursão em destaque.\nVá para "Todas as Excursões" e marque suas favoritas com uma estrela ★',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: featuredExcursions.length,
      itemBuilder: (context, index) {
        final excursion = featuredExcursions[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: const Color(0xFF2A2A2A),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/excursion_details', arguments: excursion.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(excursion.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(excursion.date), style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Constrói o menu lateral (Drawer) COMPLETO da aplicação.
  Drawer _buildAppDrawer(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
            onTap: () => Navigator.pop(context), // Ação: apenas fecha o drawer.
          ),
          ListTile(
            leading: const Icon(Icons.tour, color: Colors.white),
            title: const Text('Todas as Excursões', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExcursionsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text('Clientes', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsListPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.white),
            title: const Text('Finanças', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FinancePage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Configurações', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Criar e navegar para a tela de Configurações
              // Ex: Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tela de Configurações a ser implementada!')),
              );
            },
          ),
          const Divider(color: Colors.white38),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sair', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // Não precisa de navegação aqui se você tiver um AuthWrapper.
            },
          ),
        ],
      ),
    );
  }
}
