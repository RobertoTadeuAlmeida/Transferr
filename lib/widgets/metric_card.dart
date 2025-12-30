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
    // 1. Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      // O Card já é estilizado pelo cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 2. Os textos agora usam o textTheme
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  // 3. O indicador de progresso agora usa o progressIndicatorTheme
                  child: CircularProgressIndicator(
                    value: percentage.isNaN ? 0 : percentage, // Evita erro com NaN
                    strokeWidth: 8,
                    // A cor de fundo (track) e a cor do valor vêm do tema
                  ),
                ),
                Text(
                  percentage.isNaN ? '0%' : '${(percentage * 100).toStringAsFixed(0)}%',
                  style: textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subValue!,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
