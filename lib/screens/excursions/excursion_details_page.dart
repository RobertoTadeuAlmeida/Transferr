import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart'; // Importe o tema para as cores
import 'package:transferr/utils/extensions.dart';
import 'package:transferr/utils/double_extensions.dart'; // Importe para o .toCurrency()
import '../../models/enums.dart';
import '../../models/excursion.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_excursion_page.dart';
import 'excursion_dashboard_page.dart';

class ExcursionDetailsPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDetailsPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final Excursion? excursion = context.select<ExcursionProvider, Excursion?>(
          (p) => p.getExcursionById(excursionId),
    );
    final textTheme = Theme.of(context).textTheme;

    if (excursion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(child: Text('Excursão não encontrada.', style: textTheme.bodyLarge)),
      );
    }

    return Scaffold(
      // O AppBar já é estilizado pelo tema
      appBar: AppBar(
        title: Text(excursion.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Excursão',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditExcursionPage(excursion: excursion),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context: context,
              title: 'Detalhes da Excursão',
              details: {
                'Local:': excursion.location,
                'Data:': DateFormat('dd/MM/yyyy').format(excursion.date),
                'Preço:': excursion.pricePerPerson.toCurrency(),
                'Status:': excursion.status.name.capitalize(),
              },
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              context: context,
              title: 'Resumo Financeiro',
              details: {
                'Confirmados:': '${excursion.participants.length} passageiros',
                'Renda Bruta:': excursion.grossRevenue.toCurrency(),
                'Renda Líquida (Est.):': excursion.netRevenue.toCurrency(),
              },
            ),
            const SizedBox(height: 20),
            _buildParticipantsCard(context, excursion),
          ],
        ),
      ),
    );
  }

  // O Card e os TextStyles agora vêm do tema
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Map<String, String> details,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      // Estilo (cor, shape, elevação) vem do cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...details.entries.map((entry) => _buildDetailRow(context, entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(BuildContext context, Excursion excursion) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Participantes', style: textTheme.headlineSmall),
                // O TextButton já é estilizado pelo tema
                TextButton.icon(
                  icon: const Icon(Icons.people_alt_outlined),
                  label: const Text('Gerenciar'),
                  onPressed: () {
                    // A navegação para a dashboard funciona como gerenciamento
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (ctx) => ExcursionDashboardPage(excursionId: excursion.id!)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (excursion.participants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Nenhum participante cadastrado.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: excursion.participants.length,
                itemBuilder: (ctx, index) {
                  final participant = excursion.participants[index];
                  // As cores agora vêm do tema
                  final statusColor = participant.paymentStatus == PaymentStatus.paid
                      ? AppTheme.successColor
                      : AppTheme.warningColor;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      participant.paymentStatus == PaymentStatus.paid
                          ? Icons.check_circle
                          : Icons.hourglass_top_rounded,
                      color: statusColor,
                    ),
                    title: Text(participant.name, style: textTheme.bodyLarge),
                    trailing: Text(
                      participant.paymentStatus.name.capitalize(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
