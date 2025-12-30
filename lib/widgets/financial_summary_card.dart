import 'package:flutter/material.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 1. Importar o tema
import 'package:transferr/utils/double_extensions.dart';
import '../../../models/excursion.dart';

class FinancialSummaryCard extends StatelessWidget {
  final Excursion excursion;
  const FinancialSummaryCard({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    // 2. Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      // A aparência do Card já é controlada pelo cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. O título agora usa o textTheme
            Text('Análise Financeira', style: textTheme.titleLarge),
            const Divider(height: 24), // O Divider usa as cores padrão do tema
            _buildInfoRow(
              context, // Passa o contexto para o helper
              icon: Icons.celebration_outlined,
              label: 'Cortesias',
              value: '${excursion.totalFreeParticipants} participante(s)',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.hourglass_bottom_outlined,
              label: 'Pagamentos Pendentes',
              value: '${excursion.totalPendingParticipants} participante(s)',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.show_chart_rounded,
              label: 'Faturamento Máx. Possível',
              value: excursion.expectedRevenueFromConfirmed.toCurrency(),
              // 4. Cores de status vêm do tema
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Renda Bruta Atual',
              value: excursion.grossRevenue.toCurrency(),
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // 5. O método auxiliar agora usa o tema para estilização
  Widget _buildInfoRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        Color? color,
      }) {
    final textTheme = Theme.of(context).textTheme;
    // Define uma cor padrão baseada no tema
    final defaultColor = textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Row(
      children: [
        Icon(icon, color: color ?? defaultColor, size: 20),
        const SizedBox(width: 16),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? defaultColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: color ?? defaultColor),
            textAlign: TextAlign.end, // Alinha o valor à direita para melhor visualização
          ),
        ),
      ],
    );
  }
}
