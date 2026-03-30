import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/passenger_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/excursion.dart';
import '../../models/enums.dart';
import '../../models/passenger.dart';
import '../../models/expense.dart';
import 'widgets/excursion_stats_card.dart';
import '../passengers/passengers_list_page.dart';
import 'add_excursion_page.dart';
import 'checkin_page.dart';

class ExcursionDashboardPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDashboardPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final passengerProvider = context.read<PassengerProvider>();
    
    final authProvider = context.watch<AuthProvider>();
    final companyId = authProvider.currentUser?.company ?? '';

    final excursion = excursionProvider.getExcursionById(excursionId);

    if (excursion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isCompleted = excursion.status == ExcursionStatus.concluida;
    final bool isCanceled = excursion.status == ExcursionStatus.cancelada;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Viagem'),
        actions: [
          if (!isCompleted && !isCanceled)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _navigateToEdit(context, excursion),
            ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: excursionProvider.watchExpenses(excursionId),
        builder: (context, expenseSnapshot) {
          final expenses = expenseSnapshot.data ?? [];
          final double totalExpenses = expenses.fold(0, (sum, item) => sum + item.value);

          return StreamBuilder<List<Passenger>>(
            stream: passengerProvider.watchPassengers(excursionId, companyId),
            builder: (context, passengerSnapshot) {
              final passengers = passengerSnapshot.data ?? [];
              final double faturamentoReal = passengers.fold(
                0, (sum, p) => sum + p.depositValue
              );
              
              final double lucroAtual = faturamentoReal - totalExpenses;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoExpansionTile(excursion),
                  const SizedBox(height: 12),
                  
                  _buildOperationalControl(context, excursion),
                  
                  // TDD: Adicionando o botão de cancelamento se não estiver concluída/cancelada
                  if (!isCompleted && !isCanceled)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: () => _confirmCancel(context, excursionProvider, excursionId),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                        label: const Text("CANCELAR VIAGEM", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  const SizedBox(height: 20),

                  ExcursionStatsCard(
                    totalSeats: excursion.totalSeats,
                    reservedSeats: excursion.reservedSeats,
                    excursion: excursion,
                  ),

                  const SizedBox(height: 32),
                  const _SectionTitle(title: 'Operação'),

                  _MenuActionTile(
                    title: "Lista de Passageiros",
                    subtitle: (isCompleted || isCanceled)
                        ? "Histórico da lista de presença" 
                        : "${excursion.paidSeats} de ${excursion.reservedSeats} passagens pagas",
                    icon: Icons.people_alt_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PassengersListPage(
                              excursionId: excursionId, 
                              readOnly: isCompleted || isCanceled
                            ),
                      ),
                    ),
                  ),

                  _MenuActionTile(
                    title: "Mapa de Assentos",
                    subtitle: (isCompleted || isCanceled) ? "Ocupação final da viagem" : "Visualizar ocupação física",
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
                          'readOnly': isCompleted || isCanceled,
                        },
                      );
                    },
                  ),

                  if (!isCompleted && !isCanceled)
                    _MenuActionTile(
                      title: "Check-in de Operações",
                      subtitle: "Confirmação de embarque e desembarque",
                      icon: Icons.fact_check_outlined,
                      color: AppTheme.successColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckInPage(
                              excursionId: excursionId,
                              destinationName: excursion.idMainDestination,
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Administrativo'),

                  _MenuActionTile(
                    title: "Relatório Financeiro",
                    subtitle: "Lucro Atual: R\$ ${lucroAtual.toStringAsFixed(2)}",
                    icon: Icons.payments_outlined,
                    color: lucroAtual >= 0 ? Colors.green : Colors.red,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/excursion-finance',
                        arguments: excursion,
                      );
                    },
                  ),
                  
                  if (isCompleted || isCanceled)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          isCanceled 
                            ? "Viagem CANCELADA em ${DateFormat('dd/MM/yyyy').format(excursion.updatedAt ?? DateTime.now())}"
                            : "Viagem encerrada em ${DateFormat('dd/MM/yyyy').format(excursion.updatedAt ?? DateTime.now())}\nOs dados desta excursão não podem mais ser alterados.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, ExcursionProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Cancelamento"),
        content: const Text("Tem certeza que deseja cancelar esta viagem? Esta ação não pode ser desfeita e os passageiros ficarão sem vínculo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLTAR")),
          ElevatedButton(
            onPressed: () {
              provider.cancelExcursion(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("CANCELAR VIAGEM"),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalControl(BuildContext context, Excursion excursion) {
    if (excursion.status == ExcursionStatus.concluida || excursion.status == ExcursionStatus.cancelada) {
      final isCancel = excursion.status == ExcursionStatus.cancelada;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isCancel ? Colors.red : AppTheme.successColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isCancel ? Colors.red : AppTheme.successColor).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isCancel ? Icons.cancel_outlined : Icons.lock_outline, color: isCancel ? Colors.red : AppTheme.successColor, size: 20),
            const SizedBox(width: 8),
            Text(
              isCancel ? "VIAGEM CANCELADA" : "ARQUIVO HISTÓRICO CONCLUÍDO",
              style: TextStyle(
                color: isCancel ? Colors.red : AppTheme.successColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (excursion.status == ExcursionStatus.emAndamento) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckInPage(
                  excursionId: excursion.id,
                  destinationName: excursion.idMainDestination,
                  isFinishing: true,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckInPage(
                  excursionId: excursion.id,
                  destinationName: excursion.idMainDestination,
                  isStarting: true,
                ),
              ),
            );
          }
        },
        icon: Icon(
          excursion.status == ExcursionStatus.emAndamento
              ? Icons.flag_rounded
              : Icons.play_arrow_rounded,
          size: 24,
        ),
        label: Text(
          excursion.status == ExcursionStatus.emAndamento
              ? "FINALIZAR VIAGEM (CHECK-OUT)"
              : "INICIAR VIAGEM",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: excursion.status == ExcursionStatus.emAndamento
              ? Colors.purple
              : Colors.orangeAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

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
            color: Colors.grey[900]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
