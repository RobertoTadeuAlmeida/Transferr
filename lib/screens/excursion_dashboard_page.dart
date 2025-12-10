import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/excursion.dart';
import '../providers/client_provider.dart';
import '../providers/excursion_provider.dart';
import 'excursions/add_edit_excursion_page.dart';

class ExcursionDashboardPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDashboardPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExcursionProvider>();
    final Excursion? excursion = context.select<ExcursionProvider, Excursion?>(
          (p) => p.getExcursionById(excursionId),
    );

    if (excursion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Excursão não encontrada')),
        body: const Center(
          child: Text('A excursão pode ter sido removida.'),
        ),
      );
    }

    // --- Lógica para os contadores de progresso ---
    final double occupiedSeatsPercentage = excursion.totalSeats > 0
        ? excursion.totalClientsConfirmed / excursion.totalSeats
        : 0.0;

    final double paymentPercentage = excursion.totalClientsConfirmed > 0
        ? excursion.totalPaymentsMade / excursion.totalClientsConfirmed
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(excursion.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleMenuSelection(context, value, excursion, provider);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'editar',
                child: ListTile(leading: Icon(Icons.edit), title: Text('Editar')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'concluir',
                enabled: excursion.status == ExcursionStatus.scheduled,
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Concluir Excursão'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'cancelar',
                enabled: excursion.status == ExcursionStatus.scheduled,
                child: const ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Cancelar Excursão'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(excursion),
            const SizedBox(height: 20),
            Row(
              children: [
                // --- Card de Pagamentos com Progresso ---
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pagantes',
                    value: '${excursion.totalPaymentsMade}/${excursion.totalClientsConfirmed}',
                    percentage: paymentPercentage,
                  ),
                ),
                const SizedBox(width: 16),
                // --- Card de Assentos com Progresso ---
                Expanded(
                  child: _buildMetricCard(
                    title: 'Assentos',
                    value: '${excursion.totalClientsConfirmed}/${excursion.totalSeats}',
                    percentage: occupiedSeatsPercentage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFinancialSummaryCard(excursion),
            // TODO: Adicionar widget para mostrar participantes
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ESTÁTICOS ---

  // MODIFICADO: _buildMetricCard agora é um widget de progresso
  static Widget _buildMetricCard({
    required String title,
    required String value,
    required double percentage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            // Stack para colocar o texto sobre o indicador de progresso
            Stack(
              alignment: Alignment.center,
              children: [
                // Indicador de Progresso Circular
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage, // O valor do progresso (de 0.0 a 1.0)
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade700,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                  ),
                ),
                // Texto da porcentagem no centro
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Texto com os números absolutos (ex: 15/40)
            Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ... (O restante dos seus métodos estáticos permanece o mesmo)

  static void _handleMenuSelection(BuildContext context, String value, Excursion excursion, ExcursionProvider provider) {
    switch (value) {
      case 'editar':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddEditExcursionPage(excursion: excursion)),
        );
        break;
      case 'concluir':
        _showConfirmationDialog(
          context: context,
          title: 'Concluir Excursão?',
          content: 'Esta ação marcará a excursão como "concluída". Você confirma?',
          onConfirm: () {
            Navigator.of(context).pop();
            provider.updateExcursionStatus(excursion.id!, ExcursionStatus.completed);
            Navigator.of(context).pop();
          },
        );
        break;
      case 'cancelar':
        _showConfirmationDialog(
          context: context,
          title: 'Cancelar Excursão?',
          content: 'Esta ação é irreversível e marcará a excursão como "cancelada".',
          onConfirm: () {
            Navigator.of(context).pop();
            provider.updateExcursionStatus(excursion.id!, ExcursionStatus.canceled);
            Navigator.of(context).pop();
          },
        );
        break;
    }
  }

  static Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Voltar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
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

  static Widget _buildInfoCard(Excursion excursion) {
    final status = excursion.status;
    final statusColor = switch (status) {
      ExcursionStatus.scheduled => Colors.cyan,
      ExcursionStatus.completed => Colors.green,
      ExcursionStatus.canceled => Colors.red,
      ExcursionStatus.confirmed => Colors.blue,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Informações Gerais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status.name.toUpperCase()),
                  backgroundColor: statusColor,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Data', DateFormat('dd/MM/yyyy').format(excursion.date)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Local', excursion.location),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people, 'Capacidade', '${excursion.totalSeats} assentos'),
            if (excursion.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text(excursion.description, style: const TextStyle(color: Colors.white70, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 16),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
      ],
    );
  }

  static Card _buildFinancialSummaryCard(Excursion excursion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo Financeiro da Excursão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(Icons.attach_money, 'Renda Bruta', 'R\$ ${excursion.grossRevenue.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.account_balance_wallet, 'Renda Líquida', 'R\$ ${excursion.netRevenue.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
