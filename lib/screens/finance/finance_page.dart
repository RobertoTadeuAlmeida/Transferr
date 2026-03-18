import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transferr/utils/double_extensions.dart';
import 'package:transferr/widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';

import '../../models/enums.dart';
import '../../models/excursion.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _isLoading = true;

  // Indicadores Consolidados
  double _totalProjectedRevenue = 0.0; // Faturamento Total Previsto
  double _totalEstimatedRevenue = 0.0; // Faturamento com Reservas Atuais
  int _totalExcursions = 0;
  int _totalSeats = 0;
  int _totalReserved = 0;

  FinanceFilter _selectedFilter = FinanceFilter.todos;

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento após o primeiro frame para ter acesso ao Context/Provider
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFinanceData());
  }

  /// Carrega e processa os dados usando a lógica de negócio do Model (DDD)
  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // OBTÉM A EMPRESA ATIVA (MULTI-TENANT)
      final authProvider = context.read<AuthProvider>();
      final companyId = authProvider.currentUser?.company ?? '';

      if (companyId.isEmpty) {
        throw Exception("Empresa ativa não identificada.");
      }

      // Busca na coleção correta 'excursoes' e filtra pela empresa
      Query query = FirebaseFirestore.instance
          .collection('excursoes')
          .where('empresa', isEqualTo: companyId)
          .where('excluido', isEqualTo: false); // Filtro de soft delete

      // Aplica filtros de Status
      if (_selectedFilter == FinanceFilter.concluido) {
        query = query.where('status', isEqualTo: 'CONCLUIDA');
      } else if (_selectedFilter == FinanceFilter.aberto) {
        query = query.where('status', whereIn: ['PROGRAMADA', 'EM_ANDAMENTO']);
      }

      final querySnapshot = await query.get();

      double calcProjected = 0.0;
      double calcEstimated = 0.0;
      int calcSeats = 0;
      int calcReserved = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final excursion = Excursion.fromMap(doc.id, data);

        // OPERAÇÃO LOCAL (DDD): Usando os getters calculados no Model
        calcProjected += excursion.faturamentoPrevisto;
        calcEstimated += excursion.faturamentoEstimadoAtual;
        calcSeats += excursion.totalSeats;
        calcReserved += excursion.reservedSeats;
      }

      if (mounted) {
        setState(() {
          _totalProjectedRevenue = calcProjected;
          _totalEstimatedRevenue = calcEstimated;
          _totalSeats = calcSeats;
          _totalReserved = calcReserved;
          _totalExcursions = querySnapshot.docs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[FinancePage] Erro: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Painel Financeiro Geral'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFinanceData,
        child: _isLoading ? _buildLoadingSkeleton() : _buildContent(theme, textTheme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildFilterChips(),
        const SizedBox(height: 20),

        // CARD PRINCIPAL: RESUMO DE VALORES
        _buildMainSummaryCard(theme, textTheme),

        const SizedBox(height: 16),

        // CARD SECUNDÁRIO: MÉTRICAS DE OCUPAÇÃO
        _buildOccupancyCard(theme, textTheme),
      ],
    );
  }

  Widget _buildMainSummaryCard(ThemeData theme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text('Consolidado Monetário', style: textTheme.titleMedium),
              ],
            ),
            const Divider(height: 32),
            _buildRow('Total Previsto (100%):', _totalProjectedRevenue.toCurrency(), textTheme),
            const SizedBox(height: 16),
            _buildRow(
              'Total Estimado (Reservas):',
              _totalEstimatedRevenue.toCurrency(),
              textTheme,
              isHighlight: true,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            _buildFooterInfo('Baseado em $_totalExcursions excursões da sua empresa.'),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyCard(ThemeData theme, TextTheme textTheme) {
    final double percent = _totalSeats > 0 ? (_totalReserved / _totalSeats) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ocupação Geral", style: textTheme.bodyMedium),
                Text("${(percent * 100).toStringAsFixed(1)}%",
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text("$_totalReserved de $_totalSeats assentos ocupados",
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildRow(String label, String value, TextTheme textTheme, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        Text(value, style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? Colors.white,
          fontSize: isHighlight ? 22 : 18,
        )),
      ],
    );
  }

  Widget _buildFooterInfo(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FinanceFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                  _loadFinanceData();
                }
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.white10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(height: 40, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(height: 200, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}
