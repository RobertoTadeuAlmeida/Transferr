// lib/screens/excursions/widgets/info_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/excursion.dart';
import '../../../models/enums.dart';

// Helper local que será movido junto
Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
  return Row(
    children: [
      Icon(icon, color: color ?? Colors.white70, size: 20),
      const SizedBox(width: 16),
      Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      Expanded(child: Text(value, style: TextStyle(color: color ?? Colors.white70))),
    ],
  );
}

class InfoCard extends StatelessWidget {
  final Excursion excursion;

  const InfoCard({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    final status = excursion.status;
    final statusColor = switch (status) {
      ExcursionStatus.agendada => Colors.cyan,
      ExcursionStatus.realizada => Colors.green,
      ExcursionStatus.cancelada => Colors.red,
      ExcursionStatus.confirmada => Colors.blue,
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
            const SizedBox(height: 12),
            _buildInfoRow(Icons.price_check, 'Valor por Pessoa', 'R\$ ${excursion.pricePerPerson.toStringAsFixed(2)}'),
            if (excursion.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text(excursion.description, style: const TextStyle(color: Colors.white70, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
