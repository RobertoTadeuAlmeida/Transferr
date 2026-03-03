import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/passenger.dart';
import '../providers/excursion_provider.dart';
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

    // Busca a excursão para saber o preço base e calcular o saldo
    final excursion = context.watch<ExcursionProvider>().excursions.firstWhere(
          (e) => e.id == excursionId,
      orElse: () => throw Exception("Excursão não encontrada"),
    );

    final double amountPaid = passenger.depositValue;
    final double remaining = excursion.basePrice - amountPaid;
    final bool isPaidInFull = remaining <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: _buildSeatBadge(theme),
            title: Text(
              passenger.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Valor Pago
                    Text(
                      'Pago: R\$ ${amountPaid.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isPaidInFull ? AppTheme.successColor : theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Badge de Menor de Idade (Importante para pré-excursão/documentação)
                    if (passenger.isMinor)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'MENOR',
                          style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: _buildFinancialTrailing(theme, remaining, isPaidInFull),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatBadge(ThemeData theme) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('POLT', style: TextStyle(fontSize: 7, color: Colors.white54)),
            Text(
              passenger.seatNumber.isNotEmpty ? passenger.seatNumber : '--',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTrailing(ThemeData theme, double remaining, bool isPaidInFull) {
    if (isPaidInFull) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 28),
          Text('QUITADO', style: TextStyle(color: AppTheme.successColor, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'FALTA',
          style: TextStyle(color: Colors.red.shade300, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        Text(
          'R\$ ${remaining.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
