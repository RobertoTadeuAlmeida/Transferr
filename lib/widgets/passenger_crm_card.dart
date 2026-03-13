import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../config/theme/app_theme.dart';
import '../screens/passengers/passenger_details_page.dart';

class PassengerCrmCard extends StatelessWidget {
  final Passenger passenger;
  final Widget? trailing; 
  final VoidCallback? onTap;

  const PassengerCrmCard({
    super.key,
    required this.passenger,
    this.trailing,
    this.onTap,
  });

  /// Define o texto de status baseado na atividade do passageiro
  String _getActivityStatus(bool isTraveling) {
    if (isTraveling) {
      return 'Passageiro em excursão ativa';
    }

    if (passenger.totalTrips > 0) {
      return 'Cliente Fiel (${passenger.totalTrips} viagens)';
    }

    return 'Novo Passageiro';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // MELHORIA: Usa o getter centralizado do modelo para evitar erros de null safety
    final bool isTraveling = passenger.isCurrentlyTraveling;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTraveling ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isTraveling ? AppTheme.successColor.withValues(alpha: 0.3) : Colors.white10,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PassengerDetailsPage(passenger: passenger)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isTraveling
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    child: Icon(
                        Icons.person,
                        color: isTraveling ? AppTheme.successColor : Colors.white54,
                        size: 30
                    ),
                  ),
                  if (isTraveling)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.sync, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Informações centrais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTraveling ? AppTheme.successColor : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                            isTraveling ? Icons.directions_bus : Icons.history,
                            size: 12,
                            color: isTraveling ? AppTheme.successColor : theme.hintColor
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getActivityStatus(isTraveling),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isTraveling ? AppTheme.successColor : theme.hintColor,
                            fontWeight: isTraveling ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                trailing!
              else
                _buildTripBadge(theme, isTraveling),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripBadge(ThemeData theme, bool isTraveling) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTraveling
            ? AppTheme.successColor.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isTraveling
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : Colors.white10
        ),
      ),
      child: Column(
        children: [
          Text(
            '${passenger.totalTrips}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isTraveling ? AppTheme.successColor : AppTheme.primaryColor,
            ),
          ),
          Text(
            'VIAGENS',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isTraveling ? AppTheme.successColor.withValues(alpha: 0.6) : Colors.white38
            ),
          ),
        ],
      ),
    );
  }
}
