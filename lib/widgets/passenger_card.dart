import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/passenger.dart';
import '../models/enums.dart';
import '../providers/passenger_provider.dart';
import '../providers/excursion_provider.dart';

class PassengerCard extends StatelessWidget {
  final Passenger passenger;
  final String excursionId;
  final VoidCallback? onTap;

  const PassengerCard({
    super.key,
    required this.passenger,
    required this.excursionId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final excursion = context.watch<ExcursionProvider>().excursions.firstWhere(
          (e) => e.id == excursionId,
      orElse: () => throw Exception("Excursão não encontrada"),
    );

    final double amountPaid = passenger.depositValue;
    final double remaining = excursion.basePrice - amountPaid;

    return Card(
      // O CardTheme do seu app_theme.dart já cuida do arredondamento e cor
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: ListTile(
          // O ListTileTheme do seu tema já define as cores de ícone e textos
          leading: _buildSeatBadge(context),
          title: Text(
            passenger.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Pago: R\$ ${amountPaid.toStringAsFixed(2)}',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (remaining > 0)
                    Text(
                      'Falta: R\$ ${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                ],
              ),
            ],
          ),
          trailing: _buildStatusIcon(context),
        ),
      ),
    );
  }

  Widget _buildSeatBadge(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        // Usando a primaryColor definida no seu AppTheme
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          passenger.seatNumber ?? '--',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final status = passenger.statusEmbarque;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(status.icon, color: status.color, size: 20),
        const SizedBox(height: 2),
        Text(
          status.label.toUpperCase(),
          style: TextStyle(color: status.color, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}