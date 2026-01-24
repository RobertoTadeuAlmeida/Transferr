import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/excursion.dart';
import '../providers/excursion_provider.dart';
import '../providers/auth_provider.dart'; // Importe seu AuthProvider
import '../widgets/app_drawer.dart';
import '../widgets/excursion_card.dart';
import 'excursions/excursion_dashboard_page.dart';

class HomePage extends StatefulWidget { // Alterado para StatefulWidget para gerenciar a inicialização
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    // Inicia a escuta assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.id;
    if (uid != null) {
      context.read<ExcursionProvider>().listenToExcursions(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para reagir às mudanças no provider
    final excursionProvider = context.watch<ExcursionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final activeExcursions = excursionProvider.activeExcursions;
    final uid = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: excursionProvider.isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
        // Correção: Agora passamos o uid do authProvider
        onRefresh: () async {
          if (uid != null) {
            excursionProvider.listenToExcursions(uid);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Resumo Operacional
            SliverToBoxAdapter(
              child: _QuickStatsHeader(excursions: activeExcursions),
            ),

            // 2. Título da Seção
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Próximas Saídas'),
            ),

            // 3. Lista de Viagens Ativas ou Estado Vazio
            activeExcursions.isEmpty
                ? SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _ExcursionListItem(
                    excursion: activeExcursions[index],
                  ),
                  childCount: activeExcursions.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/excursions'),
        label: const Text('Todas Viagens'),
        icon: const Icon(Icons.list_alt_rounded),
      ),
    );
  }

  // Skeleton Loading mais refinado
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Componente de Estatísticas Rápidas
class _QuickStatsHeader extends StatelessWidget {
  final List<Excursion> excursions;
  const _QuickStatsHeader({required this.excursions});

  @override
  Widget build(BuildContext context) {
    int totalVagas = 0;
    int totalReservas = 0;

    for (var e in excursions) {
      totalVagas += e.totalSeats;
      totalReservas += e.reservedSeats;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _StatCard(
            label: 'Viagens Ativas',
            value: '${excursions.length}',
            color: Colors.blue,
            icon: Icons.directions_bus,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Ocupação Total',
            value: '$totalReservas/$totalVagas',
            color: Colors.orange,
            icon: Icons.people,
          ),
        ],
      ),
    );
  }
}

/// Card de Estatística Individual
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color.withOpacity(0.7)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de Seção padronizado
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

/// Item da lista encapsulado para limpeza do Builder
class _ExcursionListItem extends StatelessWidget {
  final Excursion excursion;
  const _ExcursionListItem({required this.excursion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExcursionCard(
        excursion: excursion,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExcursionDashboardPage(excursionId: excursion.id!),
          ),
        ),
      ),
    );
  }
}

/// Estado Vazio (Empty State)
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[800]),
        const SizedBox(height: 16),
        const Text(
          'Nenhuma viagem para os próximos dias',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/add-excursion'),
          icon: const Icon(Icons.add),
          label: const Text('Criar Nova Excursão'),
        ),
      ],
    );
  }
}