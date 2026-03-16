import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../config/theme/app_theme.dart';

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
    final isPaid = passenger.isPaid;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPaid 
              ? AppTheme.successColor.withValues(alpha: 0.3) 
              : theme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar / Poltrona
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isPaid 
                  ? AppTheme.successColor.withValues(alpha: 0.1) 
                  : theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  passenger.seatNumber.isEmpty ? '?' : passenger.seatNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? AppTheme.successColor : theme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info Nome / Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passenger.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(status: passenger.statusEmbarque),
                      if (passenger.isMinor) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'MENOR',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Indicador Financeiro
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  isPaid ? Icons.check_circle : Icons.pending_actions,
                  size: 20,
                  color: isPaid ? AppTheme.successColor : AppTheme.primaryColor,
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid ? 'PAGO' : 'PENDENTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? AppTheme.successColor : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final dynamic status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.value) {
      case 'embarcou':
        color = Colors.blue;
        break;
      case 'parada':
        color = Colors.orange;
        break;
      case 'desembarcou':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toString().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
