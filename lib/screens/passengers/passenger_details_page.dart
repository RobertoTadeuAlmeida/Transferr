import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import '../../models/passenger.dart';
import '../../models/excursion.dart';
import '../excursions/widgets/excursion_card.dart';
import '../../config/theme/app_theme.dart';
import 'add_passenger_page.dart';

class PassengerDetailsPage extends StatelessWidget {
  final String? excursionId;
  final Passenger passenger;

  const PassengerDetailsPage({
    super.key,
    this.excursionId,
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final bool isInExcursion = excursionId != null && excursionId!.isNotEmpty;

    return StreamBuilder<List<Passenger>>(
      stream: isInExcursion
          ? context.read<PassengerProvider>().watchPassengers(excursionId!)
          : context.read<PassengerProvider>().globalPassengersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar dados"));
        }

        // Localiza o passageiro atualizado na stream para manter a reatividade total (ex: poltrona, status, pagamento)
        final currentPassenger =
            snapshot.data?.firstWhere(
              (p) => p.id == passenger.id,
              orElse: () => passenger,
            ) ??
            passenger;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestão do Passageiro'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPassengerPage(
                      excursionId: excursionId ?? '',
                      passenger: currentPassenger,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isInExcursion) ...[
                  _FinancialCard(
                    passenger: currentPassenger,
                    excursionId: excursionId!,
                    formatter: currencyFormat,
                  ),
                  const SizedBox(height: 24),
                ],

                _buildSectionHeader(
                  context,
                  Icons.person_outline,
                  'Dados do Viajante',
                ),
                _InfoCard(
                  passenger: currentPassenger,
                  isInExcursion: isInExcursion,
                ),

                if (currentPassenger.isMinor &&
                    currentPassenger.guardian != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    Icons.family_restroom_outlined,
                    'Responsável Legal',
                    color: Colors.amber,
                  ),
                  _GuardianCard(guardian: currentPassenger.guardian!),
                ],

                const SizedBox(height: 32),
                _buildSectionHeader(
                  context,
                  Icons.history,
                  'Histórico de Viagens',
                ),
                _PassengerHistorySection(passengerId: currentPassenger.id),

                const SizedBox(height: 48),
                _DeleteButton(passenger: currentPassenger),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    Color? color,
  }) {
    final primary = color ?? Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final Passenger passenger;
  final String excursionId;
  final NumberFormat formatter;

  const _FinancialCard({
    required this.passenger,
    required this.excursionId,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final excursion = context.watch<ExcursionProvider>().excursions.firstWhere(
      (e) => e.id == excursionId,
      orElse: () => Excursion(
        id: '',
        name: '',
        idMainDestination: '',
        startDate: DateTime.now(),
        returnDate: DateTime.now(),
        basePrice: 0,
        totalSeats: 0,
        slug: '',
        idResponsible: '',
      ),
    );

    final double valorFaltante = excursion.basePrice - passenger.depositValue;
    // Considera pago se a flag isPaid estiver true ou se o valor faltante for zero
    final bool isTotalPaid = valorFaltante < excursion.basePrice;

    return Card(
      color: isTotalPaid ? AppTheme.successColor.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isTotalPaid ? AppTheme.successColor : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Financeiro da Viagem",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isTotalPaid)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(
              'Valor da Excursão:',
              formatter.format(excursion.basePrice),
            ),
            _DetailRow(
              'Total Pago:',
              formatter.format(passenger.depositValue),
              valueColor: isTotalPaid
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
            ),

            const SizedBox(height: 12),
            if (!isTotalPaid) ...[
              _PendingBadge(amount: formatter.format(valorFaltante)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePayment(context, excursion.basePrice),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text("DAR BAIXA TOTAL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "PAGO TOTALMENTE",
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Botão de Desvincular da Excursão
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _confirmUnlink(context),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text("DESVINCULAR DA EXCURSÃO"),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnlink(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remover da Viagem?"),
        content: const Text(
          "O passageiro sairá da lista desta excursão, mas continuará cadastrado no seu sistema.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              await context.read<PassengerProvider>().unlinkPassenger(
                context: context,
                passengerId: passenger.id,
                excursionId: excursionId,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "${passenger.name} foi removido desta excursão.",
                    ),
                    backgroundColor: Colors.orangeAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                Navigator.pop(context);
              }
            },
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  void _handlePayment(BuildContext context, double total) async {
    await context.read<PassengerProvider>().updateOperationalData(
      context: context,
      excursionId: excursionId,
      passengerId: passenger.id,
      depositValue: total,
      totalValue: total,
    );
  }
}

class _PassengerHistorySection extends StatelessWidget {
  final String passengerId;

  const _PassengerHistorySection({required this.passengerId});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ExcursionProvider>().excursions.where((
      excursion,
    ) {
      // Regra: Excursões que já aconteceram ou onde ele está/esteve
      // Ajustar filtro conforme a necessidade do seu histórico
      return excursion.idResponsible == passengerId;
    }).toList();

    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Nenhum histórico encontrado.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) =>
          ExcursionCard(excursion: history[index], actionsEnabled: false),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Passenger passenger;
  final bool isInExcursion;

  const _InfoCard({required this.passenger, required this.isInExcursion});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _DetailRow('Nome:', passenger.name),
            _DetailRow('Documento:', passenger.document),
            _DetailRow('WhatsApp:', passenger.phone),
            if (isInExcursion)
              _DetailRow(
                'Poltrona:',
                passenger.seatNumber.isEmpty
                    ? 'Não definida'
                    : passenger.seatNumber,
              ),
            _DetailRow('Idade:', '${passenger.age} anos'),
          ],
        ),
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final dynamic guardian;

  const _GuardianCard({required this.guardian});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _DetailRow('Nome:', guardian.name),
            _DetailRow('Documento:', guardian.document),
            _DetailRow('Contato:', guardian.phone),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final String amount;

  const _PendingBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "PENDENTE:",
            style: TextStyle(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final Passenger passenger;

  const _DeleteButton({required this.passenger});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _confirmGlobalDelete(context),
        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
        label: const Text(
          'REMOVER DO SISTEMA',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _confirmGlobalDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Permanente?"),
        content: Text(
          "Deseja remover ${passenger.name} da sua base de dados? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<PassengerProvider>().deletePassenger(
                passenger.id,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("EXCLUIR TUDO"),
          ),
        ],
      ),
    );
  }
}
