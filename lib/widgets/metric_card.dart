import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final double percentage;
  final String? subValue;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.percentage,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade700,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF97316),
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            // Verifica se subValue não é nulo antes de tentar construir o widget
            if (subValue != null)
              Padding(
                // Adiciona um espaçamento apenas se o texto for construído
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subValue!,
                  // Prometemos ao compilador que subValue não é nulo aqui
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
