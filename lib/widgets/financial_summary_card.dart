import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transferr/utils/double_extensions.dart';
import '../../../models/excursion.dart';

class FinancialSummaryCard extends StatelessWidget {
  final Excursion excursion;
  const FinancialSummaryCard({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Análise Financeira', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(Icons.celebration, 'Cortesias', '${excursion.totalFreeParticipants} participante(s)'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.hourglass_bottom, 'Pagamentos Pendentes', '${excursion.totalPendingParticipants} participante(s)'),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.show_chart,
              'Faturamento Máx. Possível',
              excursion.expectedRevenueFromConfirmed.toCurrency(), // <<< USE A EXTENSÃO
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.account_balance_wallet,
              'Renda Bruta Atual',
              excursion.grossRevenue.toCurrency(), // <<< USE A EXTENSÃO
              color: const Color(0xFFF97316),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    // Este método é duplicado em InfoCard, idealmente poderia ir para um arquivo de helpers de UI.
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 20),
        const SizedBox(width: 16),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Expanded(child: Text(value, style: TextStyle(color: color ?? Colors.white70))),
      ],
    );
  }
}
