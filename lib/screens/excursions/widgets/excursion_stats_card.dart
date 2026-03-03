import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';

class ExcursionStatsCard extends StatelessWidget {
  final int totalSeats;
  final int reservedSeats;
  final int paidInFullCount;

  const ExcursionStatsCard({
    super.key,
    required this.totalSeats,
    required this.reservedSeats,
    required this.paidInFullCount,
  });

  @override
  Widget build(BuildContext context) {
    // Garante que o total nunca seja zero para evitar erro de divisão (NaN/Infinity)
    final int safeTotal = totalSeats > 0 ? totalSeats : 1;

    // Cálculo das proporções para as barras
    // O clamp garante que o valor fique entre 0.0 e 1.0 para o LinearProgressIndicator
    double reservationProgress = (reservedSeats / safeTotal).clamp(0.0, 1.0);
    double paymentProgress = (paidInFullCount / safeTotal).clamp(0.0, 1.0);

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
                _buildStatItem("Reservas", "$reservedSeats", AppTheme.primaryColor),
                _buildStatItem("Pagos", "$paidInFullCount", AppTheme.successColor),
              ],
            ),
            const SizedBox(height: 20),

            Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),

                // Representa quem ocupou a vaga mas pode não ter pago tudo.
                LinearProgressIndicator(
                  value: reservationProgress,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                ),


                // Fica por cima da laranja. Se todos pagarem, a barra fica toda verde.
                LinearProgressIndicator(
                  value: paymentProgress,
                  backgroundColor: Colors.transparent,
                  color: AppTheme.successColor,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Legenda e Porcentagem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildLegendItem("Reservado", AppTheme.primaryColor.withValues(alpha: 0.6)),
                    const SizedBox(width: 12),
                    _buildLegendItem("Pagos", AppTheme.successColor),
                  ],
                ),
                Text(
                  "${(reservationProgress * 100).toStringAsFixed(0)}% ocupado",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
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