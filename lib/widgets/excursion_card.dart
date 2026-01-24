import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../models/excursion.dart';
import '../models/enums.dart';

class ExcursionCard extends StatelessWidget {
  final Excursion excursion;
  final bool isSelected;
  final bool actionsEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExcursionCard({
    super.key,
    required this.excursion,
    this.actionsEnabled = true,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final double totalArrecadado = excursion.reservedSeats * excursion.basePrice;

    final double ocupacaoPercent = excursion.totalSeats > 0
        ? (excursion.reservedSeats / excursion.totalSeats)
        : 0.0;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (excursion.status) {
      case ExcursionStatus.emAndamento:
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.directions_bus;
        statusLabel = "EM ANDAMENTO";
        break;
      case ExcursionStatus.concluida:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle_outline;
        statusLabel = "CONCLUÍDA";
        break;
      case ExcursionStatus.cancelada:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel_outlined;
        statusLabel = "CANCELADA";
        break;
      case ExcursionStatus.programada:
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule;
        statusLabel = "PROGRAMADA";
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: isSelected ? 8 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (actionsEnabled) {
            Navigator.pushNamed(
              context,
              '/excursion-dashboard',
              arguments: excursion.id,
            );
          }
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Garante que a coluna ocupe o mínimo necessário
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Expanded(
                    child: Text(
                      excursion.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(statusIcon, color: statusColor, size: 22),
                ],
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                Icons.calendar_today_outlined,
                DateFormat("'Partida:' dd/MM/yyyy 'às' HH:mm").format(excursion.startDate),
                theme,
              ),
              const SizedBox(height: 8),

              _buildInfoRow(
                Icons.people_alt_outlined,
                '${excursion.reservedSeats} / ${excursion.totalSeats} passageiros',
                theme,
                color: excursion.isFull ? AppTheme.errorColor : null,
              ),

              const SizedBox(height: 16),

              // Barra de Ocupação
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ocupação",
                        style: textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        "${(ocupacaoPercent * 100).toStringAsFixed(0)}%",
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: excursion.isFull ? AppTheme.errorColor : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ocupacaoPercent,
                      backgroundColor: Colors.white10,
                      color: excursion.isFull ? AppTheme.errorColor : AppTheme.primaryColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const Divider(height: 32, color: Colors.white10),

              // Rodapé: Uso de Flexible em ambos para evitar overflow no right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    flex: 3, // Prioridade para o valor financeiro
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARRECADADO',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalArrecadado),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 2, // Espaço limitado para o Badge
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme, {Color? color}) {
    final defaultColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min, // Evita que o Row tente ocupar o infinito
      children: [
        Icon(icon, size: 16, color: color ?? defaultColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? defaultColor,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}