import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transferr/utils/double_extensions.dart';
import 'package:transferr/widgets/app_drawer.dart';

import '../../models/enums.dart';
import '../../models/excursion.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _isLoading = true;
  double _totalGrossRevenue = 0.0;
  double _totalNetRevenue = 0.0;
  int _totalExcursions = 0;

  // Usa o novo enum de filtro financeiro que definimos
  FinanceFilter _selectedFilter = FinanceFilter.todos;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  /// Método centralizado para carregar os dados financeiros
  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Referência para a coleção principal de excursões
      // (Ajustado para a estrutura global que estamos seguindo)
      Query query = FirebaseFirestore.instance.collection('excursions');

      // Aplica os filtros baseados nos Enums Tipados
      switch (_selectedFilter) {
        case FinanceFilter.concluido:
        // Agora usamos o nome correto do status concluído
          query = query.where('status', isEqualTo: ExcursionStatus.concluida.name);
          break;
        case FinanceFilter.aberto:
        // Filtra por excursões que ainda não foram finalizadas ou canceladas
          query = query.where('status', whereIn: [
            ExcursionStatus.programada.name,
            ExcursionStatus.programada.name,
          ]);
          break;
        case FinanceFilter.todos:
        // Sem filtro adicional
          break;
      }

      final querySnapshot = await query.get();

      double calculatedGross = 0.0;
      double calculatedNet = 0.0;

      for (var doc in querySnapshot.docs) {
        // Mapeamento seguro usando o factory fromFirestore do modelo Excursion
        final excursion = Excursion.fromFirestore(doc as QueryDocumentSnapshot<Map<String, dynamic>>);

        // As propriedades grossRevenue e netRevenue são getters calculados no modelo
        calculatedGross += excursion.totalSeats;
        calculatedNet += excursion.reservedSeats;
      }

      if (mounted) {
        setState(() {
          _totalGrossRevenue = calculatedGross;
          _totalNetRevenue = calculatedNet;
          _totalExcursions = querySnapshot.docs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro Financeiro: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar finanças: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
        title: const Text('Resumo Financeiro'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFinanceData,
        color: theme.primaryColor,
        child: _isLoading
            ? _buildLoadingSkeleton()
            : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildFilterChips(),
            const SizedBox(height: 16),

            // Card Principal de Resumo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text('Consolidado', style: textTheme.titleMedium),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildFinancialSummaryRow(
                      context: context,
                      label: 'Renda Bruta:',
                      value: _totalGrossRevenue.toCurrency(),
                    ),
                    const SizedBox(height: 16),
                    _buildFinancialSummaryRow(
                      context: context,
                      label: 'Renda Líquida Estimada:',
                      value: _totalNetRevenue.toCurrency(),
                      isHighlight: true,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Baseado em $_totalExcursions excursões no filtro "${_selectedFilter.label}".',
                              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              // Uso do withValues conforme solicitado
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white10,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFinancialSummaryRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? theme.primaryColor : Colors.white,
          ),
        ),
      ],
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
            const SizedBox(height: 16),
            Container(height: 250, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}