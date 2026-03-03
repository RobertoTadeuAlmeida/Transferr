import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/excursion_provider.dart';
import '../screens/excursions/widgets/excursion_card.dart';
import '../../config/theme/app_theme.dart';

class PassengerTravelHistory extends StatelessWidget {
  final String passengerId;

  const PassengerTravelHistory({super.key, required this.passengerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excursionProvider = context.watch<ExcursionProvider>();

    // Filtra as excursões onde este passageiro esteve presente
    // Nota: Adapte a lógica de filtro conforme sua estrutura de dados
    final history = excursionProvider.excursions.where((e) {
      // Aqui você verifica se o passageiro participou desta viagem
      return e.status != null; // Adicione sua lógica de vínculo aqui
    }).toList();

    if (history.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      shrinkWrap: true, // Importante para usar dentro de outra Column/ListView
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final excursion = history[index];

        return ExcursionCard(
          excursion: excursion,
          // No histórico do passageiro, não precisamos de seleção múltipla
          isSelected: false,
          onTap: () {
            // Opcional: Navegar para um resumo daquela viagem específica
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.map_outlined, size: 48, color: theme.disabledColor.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            'Este passageiro ainda não realizou viagens.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}