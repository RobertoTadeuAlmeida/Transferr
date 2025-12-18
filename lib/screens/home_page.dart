import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/excursion.dart';
import '../providers/excursion_provider.dart';

// 1. IMPORTE O NOVO WIDGET DO DRAWER
import '../widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final List<Excursion> featuredExcursions = excursionProvider.featuredExcursions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destaques'),
        // Não precisa mais do `leading`, pois o Scaffold adiciona
        // o botão de menu automaticamente quando um Drawer está presente.
      ),
      // 2. USE O WIDGET REUTILIZÁVEL AQUI
      drawer: const AppDrawer(),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
          : _buildFeaturedList(context, featuredExcursions),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // É melhor usar a navegação por rota nomeada que já temos
          Navigator.pushNamed(context, '/excursions');
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

// 3. O MÉTODO _buildAppDrawer FOI COMPLETAMENTE REMOVIDO DAQUI
}
