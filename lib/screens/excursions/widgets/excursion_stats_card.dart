import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';
import '../../../models/excursion.dart';

class ExcursionStatsCard extends StatelessWidget {
  final int totalSeats;
  final int reservedSeats;
  final Excursion excursion;

  const ExcursionStatsCard({
    super.key,
    required this.totalSeats,
    required this.reservedSeats,
    required this.excursion,
  });

  @override
  Widget build(BuildContext context) {
    // Cálculos de Progresso baseados nos novos campos sincronizados
    final int total = excursion.totalSeats > 0 ? excursion.totalSeats : 1;

    // Cálculo
    final int seatsOnly = excursion.totalSeats - excursion.reservedSeats;

    // Percentual de ocupação total (Reservas)
    final double percentOcupado = (excursion.reservedSeats / total).clamp(
      0.0,
      1.0,
    );

    // Percentual de quitação (Pagos Completos)
    final double percentPagos = (excursion.paidSeats / total).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Total Vagas", "$totalSeats", Colors.blueAccent),
                _buildStatItem(
                  "Reservas",
                  "$reservedSeats",
                  AppTheme.primaryColor,
                ),
                _buildStatItem(
                  "Pagos",
                  "${excursion.paidSeats}",
                  AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Stack(
              children: [
                // Fundo da barra
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),

                // Camada 1: Ocupação Total (Reservas)
                LinearProgressIndicator(
                  value: percentOcupado,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                ),

                // Camada 2: Quitação (Pagos) - Fica por cima da ocupação
                LinearProgressIndicator(
                  value: percentPagos,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.successColor,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Legenda e Detalhes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildLegendItem(
                      "Aguardando ($seatsOnly)",
                      AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    _buildLegendItem(
                      "Pagos (${excursion.paidSeats})",
                      AppTheme.successColor,
                    ),
                  ],
                ),
                Text(
                  "${(percentOcupado * 100).toStringAsFixed(0)}% ocupado",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
