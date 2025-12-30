import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 1. Importar o tema
import 'package:transferr/utils/double_extensions.dart'; // Para o .toCurrency()

import '../models/enums.dart';
import '../models/excursion.dart';

class InfoCard extends StatelessWidget {
  final Excursion excursion;

  const InfoCard({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    // 2. Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // 3. Cores do status vêm do tema
    final statusColor = switch (excursion.status) {
      ExcursionStatus.realizada => AppTheme.successColor,
      ExcursionStatus.cancelada => theme.colorScheme.error,
      _ => AppTheme.infoColor, // Para Agendada, Confirmada, etc.
    };

    return Card(
      // A aparência do Card já é controlada pelo cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 4. O título usa o textTheme
                Text('Informações Gerais', style: textTheme.titleLarge),
                Chip(
                  label: Text(excursion.status.name.toUpperCase()),
                  backgroundColor: statusColor,
                  labelStyle: textTheme.labelSmall?.copyWith(
                    color: Colors.black, // Cor escura para melhor contraste
                    fontWeight: FontWeight.bold,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24), // O Divider usa as cores padrão
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Data',
              value: DateFormat('dd/MM/yyyy').format(excursion.date),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.location_on_outlined,
              label: 'Local',
              value: excursion.location,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.people_alt_outlined,
              label: 'Capacidade',
              value: '${excursion.totalSeats} assentos',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.local_offer_outlined, // Ícone mais adequado
              label: 'Valor por Pessoa',
              value: excursion.pricePerPerson.toCurrency(), // Usa a extensão
            ),
            if (excursion.description.isNotEmpty) ...[
              const Divider(height: 24),
              // O texto da descrição usa o textTheme
              Text(
                excursion.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
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
    final defaultColor = textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
