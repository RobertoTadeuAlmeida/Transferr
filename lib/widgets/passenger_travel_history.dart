import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excursion_provider.dart';
import '../providers/passenger_provider.dart';
import '../models/passenger.dart';
import '../screens/excursions/widgets/excursion_card.dart';

class PassengerTravelHistory extends StatelessWidget {
  final Passenger passenger; // Alterado para receber o objeto completo

  const PassengerTravelHistory({super.key, required this.passenger});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excursionProvider = context.watch<ExcursionProvider>();

    // Filtra as excursões que estão na lista de histórico do passageiro
    final history = excursionProvider.excursions.where((e) {
      return passenger.tripHistory.contains(e.id);
    }).toList();

    // Ordena pela data de partida mais recente
    history.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (history.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final excursion = history[index];

        return ExcursionCard(
          excursion: excursion,
          actionsEnabled: false, // Desabilita edição/clique profundo no histórico
          onTap: () {
             Navigator.pushNamed(
              context,
              '/excursion-dashboard',
              arguments: excursion.id,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: Colors.white10,
          ),
          const SizedBox(height: 16),
          Text(
            'HISTÓRICO VAZIO',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este passageiro ainda não concluiu viagens com a empresa.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
