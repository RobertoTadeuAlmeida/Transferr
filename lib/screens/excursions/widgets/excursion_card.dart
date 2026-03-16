import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../../../models/excursion.dart';
import '../../../models/enums.dart';

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
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final bool isCompleted = excursion.status == ExcursionStatus.concluida;

    // Cálculos de Progresso
    final int total = excursion.totalSeats > 0 ? excursion.totalSeats : 1;
    final double percentOcupado = (excursion.reservedSeats / total).clamp(0.0, 1.0);
    final double percentPagos = (excursion.paidSeats / total).clamp(0.0, 1.0);

    // Configuração de Status
    final (statusColor, statusIcon, statusLabel) = _getStatusConfig();

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
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 22),
                ],
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                Icons.calendar_today_outlined,
                DateFormat(
                  "'Partida:' dd/MM/yyyy 'às' HH:mm",
                ).format(excursion.startDate),
                theme,
              ),

              const SizedBox(height: 16),

              // Barras de Progresso
              _buildProgressBar(
                label: "Ocupação (Reservas)",
                percent: percentOcupado,
                color: AppTheme.primaryColor,
                count: "${excursion.reservedSeats}/$total",
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),
              _buildProgressBar(
                label: "Pagamentos (Completos)",
                percent: percentPagos,
                color: AppTheme.successColor,
                count: "${excursion.paidSeats}/$total",
                textTheme: textTheme,
              ),

              const Divider(height: 32, color: Colors.white10),

              // Rodapé Financeiro Dinâmico
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? 'LUCRO BRUTO FINAL' : 'FATURAMENTO PREVISTO',
                        style: textTheme.labelSmall?.copyWith(
                          color: isCompleted ? AppTheme.successColor : Colors.grey,
                          fontSize: 9,
                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        // Se concluída, mostra o faturamento real que entrou. 
                        // Se não, mostra o que é previsto se vender tudo.
                        currencyFormat.format(isCompleted ? (excursion.paidSeats * excursion.basePrice) : excursion.faturamentoPrevisto),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.successColor : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/excursion-finance',
                          arguments: excursion,
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        color: AppTheme.successColor,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.successColor.withValues(
                            alpha: 0.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(statusLabel, statusColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildProgressBar({
    required String label,
    required double percent,
    required Color color,
    required String count,
    required TextTheme textTheme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            Text(
              count,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  (Color, IconData, String) _getStatusConfig() {
    switch (excursion.status) {
      case ExcursionStatus.emAndamento:
        return (AppTheme.infoColor, Icons.directions_bus, "EM ANDAMENTO");
      case ExcursionStatus.concluida:
        return (AppTheme.successColor, Icons.check_circle_outline, "CONCLUÍDA");
      case ExcursionStatus.cancelada:
        return (AppTheme.errorColor, Icons.cancel_outlined, "CANCELADA");
      default:
        return (AppTheme.warningColor, Icons.schedule, "PROGRAMADA");
    }
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    ThemeData theme, {
    Color? color,
  }) {
    final defaultColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.7,
    );
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? defaultColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color ?? defaultColor,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
