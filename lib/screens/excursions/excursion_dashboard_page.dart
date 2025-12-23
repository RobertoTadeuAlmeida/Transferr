import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/utils/double_extensions.dart';
import 'package:transferr/widgets/financial_summary_card.dart';
import 'package:transferr/widgets/info_card.dart';
import 'package:transferr/widgets/metric_card.dart';
import 'package:transferr/widgets/participants_section.dart';
import '../../models/enums.dart';
import '../../models/excursion.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_excursion_page.dart';
import 'add_passenger_page.dart';


class ExcursionDashboardPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDashboardPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final Excursion? excursion = context.select<ExcursionProvider, Excursion?>(
          (p) => p.getExcursionById(excursionId),
    );

    if (excursion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Excursão não encontrada...')),
      );
    }

    // --- A lógica de cálculo de porcentagens continua aqui ---
    final int totalParticipants = excursion.participants.length;
    final double occupiedSeatsPercentage = excursion.totalSeats > 0 ? totalParticipants / excursion.totalSeats : 0.0;
    // O progresso da arrecadação é sobre o faturamento esperado, não o máximo.
    final double revenuePercentage = excursion.expectedRevenueFromConfirmed > 0 ? excursion.grossRevenue / excursion.expectedRevenueFromConfirmed : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(excursion.name),
        actions: [_buildAppBarMenu(context, excursion)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPassengerPage(excursionId: excursionId),
          ),
        ),
        tooltip: 'Adicionar Participante',
        child: const Icon(Icons.person_add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CHAMADA AOS WIDGETS EXTERNOS ---
            InfoCard(excursion: excursion),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Arrecadado',
                    value: 'R\$ ${excursion.grossRevenue.toCurrency()}',
                    percentage: revenuePercentage,
                    subValue: 'Esperado: R\$ ${excursion.expectedRevenueFromConfirmed.toCurrency()}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCard(
                    title: 'Assentos',
                    value: '$totalParticipants/${excursion.totalSeats}',
                    percentage: occupiedSeatsPercentage,
                    subValue: '${excursion.totalSeats - totalParticipants} vagos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FinancialSummaryCard(excursion: excursion),
            const SizedBox(height: 20),
            ParticipantsSection(excursion: excursion),
          ],
        ),
      ),
    );
  }

  // Métodos de interação e navegação permanecem na página principal.
  PopupMenuButton<String> _buildAppBarMenu(BuildContext context, Excursion excursion) {
    final provider = context.read<ExcursionProvider>();
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'editar':
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditExcursionPage(excursion: excursion)));
            break;
          case 'concluir':
            _showConfirmationDialog(
              context: context,
              title: 'Concluir Excursão?',
              content: 'Esta ação marcará a excursão como "concluída". Você confirma?',
              onConfirm: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                provider.updateExcursionStatus(excursion.id!, ExcursionStatus.realizada);
                Navigator.of(context).pop(); // Volta da dashboard
              },
            );
            break;
          case 'cancelar':
            _showConfirmationDialog(
              context: context,
              title: 'Cancelar Excursão?',
              content: 'Esta ação é irreversível e marcará a excursão como "cancelada".',
              onConfirm: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                provider.updateExcursionStatus(excursion.id!, ExcursionStatus.cancelada);
                Navigator.of(context).pop(); // Volta da dashboard
              },
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'editar', child: ListTile(leading: Icon(Icons.edit), title: Text('Editar'))),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
            value: 'concluir',
            enabled: excursion.status == ExcursionStatus.agendada,
            child: const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Concluir Excursão'))),
        PopupMenuItem<String>(
            value: 'cancelar',
            enabled: excursion.status == ExcursionStatus.agendada,
            child: const ListTile(leading: Icon(Icons.cancel, color: Colors.red), title: Text('Cancelar Excursão'))),
      ],
    );
  }

  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(child: const Text('Voltar'), onPressed: () => Navigator.of(dialogContext).pop()),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: title.contains('Cancelar') ? Colors.red : Colors.green),
              onPressed: onConfirm,
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
