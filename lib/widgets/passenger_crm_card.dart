import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../config/theme/app_theme.dart';
import '../screens/passengers/passenger_details_page.dart';

class PassengerCrmCard extends StatelessWidget {
  final Passenger passenger;
  final Widget? trailing; // Novo parâmetro opcional
  final VoidCallback? onTap; // Novo parâmetro opcional para customizar o clique

  const PassengerCrmCard({
    super.key,
    required this.passenger,
    this.trailing, // Adicionado ao construtor
    this.onTap,    // Adicionado ao construtor
  });

  /// Define o texto de status baseado na atividade do passageiro
  String _getActivityStatus() {
    if (passenger.excursionId.isNotEmpty) {
      return 'Passageiro em excursão ativa';
    }

    if (passenger.lastUpdate == null) {
      return 'Sem histórico de viagens';
    }

    final now = DateTime.now();
    final lastTrip = passenger.lastUpdate!;
    final difference = now.difference(lastTrip);

    if (difference.inDays == 0) return 'Concluiu viagem hoje';
    if (difference.inDays < 30) return 'Última viagem há ${difference.inDays} dias';

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Última viagem há $months ${months == 1 ? 'mês' : 'meses'}';
    }

    return 'Inativo há mais de um ano';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTraveling = passenger.excursionId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTraveling ? 4 : 1,
      child: InkWell(
        // Se onTap for nulo, usa o comportamento padrão de abrir detalhes
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
                        ? AppTheme.successColor.withAlpha(20)
                        : theme.primaryColor.withAlpha(30),
                    child: Icon(
                        Icons.person,
                        color: isTraveling ? AppTheme.successColor : theme.primaryColor,
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
                            isTraveling ? Icons.directions_bus : Icons.calendar_today,
                            size: 12,
                            color: isTraveling ? AppTheme.successColor : theme.hintColor
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getActivityStatus(),
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

              // ÁREA DINÂMICA: Se houver trailing (botão de adicionar), mostra ele.
              // Se não, mostra o Badge de Fidelidade original.
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
            ? AppTheme.successColor.withAlpha(15)
            : theme.primaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isTraveling
                ? AppTheme.successColor.withAlpha(30)
                : theme.primaryColor.withAlpha(30)
        ),
      ),
      child: Column(
        children: [
          Text(
            '${passenger.totalTrips}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isTraveling ? AppTheme.successColor : theme.primaryColor,
            ),
          ),
          Text(
            'VIAGENS',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isTraveling ? AppTheme.successColor.withAlpha(150) : Colors.white54
            ),
          ),
        ],
      ),
    );
  }
}