import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transferr/utils/double_extensions.dart'; // Importar para o .toCurrency()
import 'package:transferr/widgets/app_drawer.dart';

import '../main.dart';
import '../models/excursion.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true; // Adiciona um estado de carregamento

  double _totalGrossRevenue = 0.0;
  double _totalNetRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data')
          .collection('excursions')
          .get();

      double calculatedGross = 0.0;
      double calculatedNet = 0.0;

      for (var doc in querySnapshot.docs) {
        final excursion = Excursion.fromFirestore(doc);
        calculatedGross += excursion.grossRevenue;
        calculatedNet += excursion.netRevenue;
      }

      if (mounted) {
        setState(() {
          _totalGrossRevenue = calculatedGross;
          _totalNetRevenue = calculatedNet;
        });
      }
    } catch (e) {
      if (mounted) {
        // 1. SnackBar usa o tema para cor de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar finanças: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acesso ao tema e aos estilos de texto
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      // 2. AppBar agora é 100% controlado pelo appBarTheme
      appBar: AppBar(
        title: const Text('Finanças Gerais'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFinanceData, // Permite "puxar para atualizar"
        color: theme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3. O Card agora usa os estilos do tema para texto
              Card(
                // A cor e o shape já vêm do cardTheme
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo Financeiro Total',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      _buildFinancialSummaryRow(
                        context,
                        label: 'Renda Bruta Total:',
                        // Usando a extensão .toCurrency()
                        value: _totalGrossRevenue.toCurrency(),
                      ),
                      const SizedBox(height: 12),
                      _buildFinancialSummaryRow(
                        context,
                        label: 'Renda Líquida Estimada:',
                        value: _totalNetRevenue.toCurrency(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Estes valores são a soma de todas as excursões já cadastradas (ativas, concluídas e canceladas).',
                        style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 4. O botão já usa o tema, sem precisar de `style` local
              ElevatedButton.icon(
                onPressed: _loadFinanceData,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. O widget auxiliar agora usa o textTheme do contexto
  Widget _buildFinancialSummaryRow(
      BuildContext context, {
        required String label,
        required String value,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.titleMedium,
        ),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
