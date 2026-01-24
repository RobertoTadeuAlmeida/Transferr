import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/passenger_provider.dart';
import '../../models/excursion.dart';
import '../../models/passenger.dart';
import '../../models/enums.dart';
import '../../widgets/excursion_stats_card.dart';
import '../passengers/passengers_list_page.dart';
import 'add_excursion_page.dart';

class ExcursionDashboardPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDashboardPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final passengerProvider = context.read<PassengerProvider>();

    final excursion = excursionProvider.excursions
        .cast<Excursion?>()
        .firstWhere((e) => e?.id == excursionId, orElse: () => null);

    if (excursion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Viagem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(context, excursion),
          ),
        ],
      ),
      body: StreamBuilder<List<Passenger>>(
        stream: passengerProvider.watchPassengers(excursionId),
        builder: (context, snapshot) {
          final passengers = snapshot.data ?? [];
          final onboardedCount = passengers
              .where((p) => p.statusEmbarque == BoardingStatus.embarcou)
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- NOVO: EXPANSION TILE PARA DETALHES ---
              _buildInfoExpansionTile(excursion),

              const SizedBox(height: 20),

              ExcursionStatsCard(
                totalSeats: excursion.totalSeats,
                reservedSeats: passengers.length,
                onboardedCount: onboardedCount,
              ),

              const SizedBox(height: 32),
              const _SectionTitle(title: 'Operação'),

              _MenuActionTile(
                title: "Lista de Passageiros",
                subtitle: "$onboardedCount de ${passengers.length} embarcados",
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PassengersListPage(excursionId: excursionId),
                  ),
                ),
              ),

              _MenuActionTile(
                title: "Mapa de Assentos",
                subtitle: "Visualizar ocupação física",
                icon: Icons.grid_view_rounded,
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/map-seats',
                    arguments: {
                      'excursionId': excursionId,
                      'totalSeats': excursion.totalSeats,
                      'title': 'Mapa de Assentos',
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
              const _SectionTitle(title: 'Administrativo'),

              _MenuActionTile(
                title: "Relatório Financeiro",
                subtitle: "Base: R\$ ${excursion.basePrice.toStringAsFixed(2)}",
                icon: Icons.payments_outlined,
                color: Colors.green,
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget do ExpansionTile refatorado
  Widget _buildInfoExpansionTile(Excursion excursion) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
        title: Text(
          excursion.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          DateFormat("'Partida:' dd/MM 'às' HH:mm").format(excursion.startDate),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.location_on_outlined,
                  "Destino",
                  excursion.idMainDestination,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.payments_outlined,
                  "Valor do Assento",
                  "R\$ ${excursion.basePrice.toStringAsFixed(2)}",
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.keyboard_return,
                  "Retorno Previsto",
                  DateFormat(
                    "dd/MM/yyyy 'às' HH:mm",
                  ).format(excursion.returnDate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToEdit(BuildContext context, Excursion excursion) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExcursionPage(excursion: excursion)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // SUBSTITUIÇÃO DO withOpacity (Obsoleto) por withValues
            color: Colors.grey[900]!.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // SUBSTITUIÇÃO DO withOpacity por withValues
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[700]),
            ],
          ),
        ),
      ),
    );
  }
}
