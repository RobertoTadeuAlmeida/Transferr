import 'package:flutter/material.dart';

class ExcursionStatsCard extends StatelessWidget {
  final int totalSeats;
  final int reservedSeats;
  final int onboardedCount; // Passageiros que já deram check-in

  const ExcursionStatsCard({
    super.key,
    required this.totalSeats,
    required this.reservedSeats,
    required this.onboardedCount
  });

  @override
  Widget build(BuildContext context) {
    // Progresso baseado em quem reservou vs quem embarcou
    double progress = reservedSeats > 0 ? (onboardedCount / reservedSeats) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Total Vagas", "$totalSeats", Colors.blue),
                _buildStatItem("Reservas", "$reservedSeats", Colors.orange),
                _buildStatItem("Embarcados", "$onboardedCount", Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: Colors.green,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              "${(progress * 100).toStringAsFixed(0)}% do embarque concluído",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}