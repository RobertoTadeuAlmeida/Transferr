import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/excursion_provider.dart';
import '../../widgets/app_drawer.dart';
import 'widgets/excursion_card.dart';
import 'excursion_dashboard_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final archived = excursionProvider.archivedExcursions;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Histórico de Viagens'),
      ),
      body: archived.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: archived.length,
              itemBuilder: (context, index) {
                final excursion = archived[index];
                return ExcursionCard(
                  excursion: excursion,
                  actionsEnabled: false, // Desabilita edição no histórico
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExcursionDashboardPage(
                          excursionId: excursion.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma viagem no histórico.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Viagens concluídas ou excluídas aparecerão aqui.",
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
