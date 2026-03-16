import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/excursion.dart';
import '../providers/excursion_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_drawer.dart';
import 'excursions/widgets/excursion_card.dart';
import 'excursions/excursion_dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hideBanner = false;
  String? _lastCompanyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      _lastCompanyId = user.company;
      _refreshData(user.id, user.company);
    }
  }

  void _refreshData(String uid, String companyId) {
    context.read<ExcursionProvider>().listenToExcursions(companyId);
    context.read<UserProvider>().initInviteStream(uid);
    context.read<UserProvider>().initCompanyStream(companyId);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final excursionProvider = context.watch<ExcursionProvider>();
    final userProvider = context.watch<UserProvider>();
    
    final user = authProvider.currentUser;
    final activeExcursions = excursionProvider.activeExcursions;

    // Detectar troca de empresa e atualizar streams
    if (user != null && user.company != _lastCompanyId) {
      _lastCompanyId = user.company;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData(user.id, user.company);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: excursionProvider.isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: () async {
                if (user != null) _refreshData(user.id, user.company);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Banner de Convite Pendente
                  if (userProvider.pendingInvites.isNotEmpty && !_hideBanner)
                    SliverToBoxAdapter(
                      child: _InviteBanner(
                        invite: userProvider.pendingInvites.first,
                        onDismiss: () => setState(() => _hideBanner = true),
                      ),
                    ),

                  // Resumo Operacional
                  SliverToBoxAdapter(
                    child: _QuickStatsHeader(excursions: activeExcursions),
                  ),

                  // Título da Seção
                  const SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Próximas Saídas'),
                  ),

                  // Lista de Viagens Ativas ou Estado Vazio
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

class _InviteBanner extends StatelessWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onDismiss;

  const _InviteBanner({required this.invite, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Você recebeu um convite para entrar na equipe de ${invite['fromCompanyName']}.",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: const Text("RESPONDER DEPOIS")),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _respond(context, userProvider, auth, 'aceito'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("ACEITAR"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _respond(BuildContext context, UserProvider provider, AuthProvider auth, String status) async {
    try {
      await provider.respondToInvite(
        inviteId: invite['id'],
        status: status,
        currentUser: auth.currentUser!,
        companyId: invite['fromCompanyId'],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'aceito' ? "Convite aceito! Empresa vinculada." : "Convite recusado."),
            backgroundColor: status == 'aceito' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao responder convite.")));
    }
  }
}

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
          _StatCard(label: 'Viagens Ativas', value: '${excursions.length}', color: Colors.blue, icon: Icons.directions_bus),
          const SizedBox(width: 12),
          _StatCard(label: 'Ocupação Total', value: '$totalReservas/$totalVagas', color: Colors.orange, icon: Icons.people),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)));
  }
}

class _ExcursionListItem extends StatelessWidget {
  final Excursion excursion;
  const _ExcursionListItem({required this.excursion});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: ExcursionCard(excursion: excursion, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExcursionDashboardPage(excursionId: excursion.id)))));
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[800]),
      const SizedBox(height: 16),
      const Text('Nenhuma viagem para os próximos dias', style: TextStyle(color: Colors.grey)),
      TextButton.icon(onPressed: () => Navigator.pushNamed(context, '/add-excursion'), icon: const Icon(Icons.add), label: const Text('Criar Nova Excursão')),
    ]);
  }
}
