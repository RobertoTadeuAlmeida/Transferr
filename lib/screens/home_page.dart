import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/excursion.dart';
import '../providers/excursion_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/excursion_card.dart'; // 1. IMPORTE O WIDGET REUTILIZÁVEL

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final List<Excursion> featuredExcursions = excursionProvider.featuredExcursions;

    return Scaffold(
      // O AppBar e o Drawer já são estilizados pelo tema
      appBar: AppBar(
        title: const Text('Destaques'),
      ),
      drawer: const AppDrawer(),
      body: excursionProvider.isLoading
      // 2. O CircularProgressIndicator agora usa a cor primária do tema
          ? const Center(child: CircularProgressIndicator())
          : _buildFeaturedList(context, featuredExcursions),
      // 3. O FloatingActionButton agora é 100% controlado pelo tema
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/excursions');
        },
        tooltip: 'Ver Todas as Excursões',
        child: const Icon(Icons.tour_outlined),
      ),
    );
  }

  /// Constrói a lista de excursões em destaque ou uma mensagem de "nenhum destaque".
  Widget _buildFeaturedList(BuildContext context, List<Excursion> featuredExcursions) {
    // Acesso aos estilos de texto do tema
    final textTheme = Theme.of(context).textTheme;

    if (featuredExcursions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // 4. O texto de status agora usa o textTheme
          child: Text(
            'Nenhuma excursão em destaque.\nVá para a tela de excursões e marque suas favoritas com uma estrela ★',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.5, // Mantém a altura da linha para melhor legibilidade
            ),
          ),
        ),
      );
    }

    // 5. O ListView agora usa o nosso widget ExcursionCard refatorado
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: featuredExcursions.length,
      itemBuilder: (context, index) {
        final excursion = featuredExcursions[index];
        // O ExcursionCard já é um Card clicável e estilizado.
        // Ele lida com o clique e navega para a Dashboard.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ExcursionCard(
            excursion: excursion,
          ),
        );
      },
    );
  }
}
