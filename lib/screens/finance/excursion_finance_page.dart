import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_theme.dart';
import '../../models/excursion.dart';
import '../../models/expense.dart'; 
import '../../providers/excursion_provider.dart';

class ExcursionFinancePage extends StatefulWidget {
  final Excursion excursion;

  const ExcursionFinancePage({super.key, required this.excursion});

  @override
  State<ExcursionFinancePage> createState() => _ExcursionFinancePageState();
}

class _ExcursionFinancePageState extends State<ExcursionFinancePage> {
  late Stream<List<Expense>> _expensesStream;
  late Stream<double> _revenueStream;
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final excursionProvider = context.read<ExcursionProvider>();
    _expensesStream = excursionProvider.watchExpenses(widget.excursion.id);
    _revenueStream = excursionProvider.getTotalRevenueStream(widget.excursion.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planilha Financeira')),
      body: StreamBuilder<List<Expense>>(
        stream: _expensesStream,
        builder: (context, snapshotExpenses) {
          return StreamBuilder<double>(
            stream: _revenueStream,
            builder: (context, snapshotRevenue) {
              // ENDIREITANDO: A UI deve aparecer se houver dados (hasData), 
              // mesmo que o ConnectionState ainda seja 'waiting'.
              final bool isLoading = (snapshotExpenses.connectionState == ConnectionState.waiting && !snapshotExpenses.hasData) ||
                                   (snapshotRevenue.connectionState == ConnectionState.waiting && !snapshotRevenue.hasData);

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final despesas = snapshotExpenses.data ?? [];
              final faturamentoReal = snapshotRevenue.data ?? 0.0;
              final totalDespesas = despesas.fold<double>(0, (sum, item) => sum + item.value);

              final faturamentoPrevisto = widget.excursion.faturamentoPrevisto;
              final lucroPrevisto = widget.excursion.calcularLucroPrevisto(totalDespesas);
              final lucroAtual = widget.excursion.calcularLucroAtual(totalDespesas, faturamentoReal);
              final custoPorAssento = widget.excursion.calcularCustoPorAssento(totalDespesas);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSummaryGrid(faturamentoPrevisto, totalDespesas, lucroPrevisto, lucroAtual),
                          const SizedBox(height: 16),
                          _buildCustoAssentoCard(custoPorAssento),
                          const SizedBox(height: 24),
                          _buildExpensesHeader(context),
                        ],
                      ),
                    ),
                  ),
                  
                  if (despesas.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        alignment: Alignment.center,
                        child: Text(
                          "Nenhuma despesa cadastrada.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ExpenseItemTile(
                            item: despesas[index],
                            formatter: _currencyFormatter,
                            onDelete: () => _confirmDelete(despesas[index].id),
                          ),
                          childCount: despesas.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExpensesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "DESPESAS LANÇADAS", 
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white60)
        ),
        TextButton.icon(
          onPressed: () {}, 
          icon: const Icon(Icons.add, size: 18, color: AppTheme.successColor),
          label: const Text("ADICIONAR", style: TextStyle(color: AppTheme.successColor)),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(double prev, double desp, double lucroP, double lucroA) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _infoCard("Faturamento Prev.", prev, Colors.blue),
        _infoCard("Total Despesas", desp, AppTheme.errorColor),
        _infoCard("Lucro Previsto", lucroP, AppTheme.successColor),
        _infoCard(
          "Lucro Atual (Em Caixa)", 
          lucroA, 
          lucroA >= 0 ? AppTheme.successColor : Colors.red
        ),
      ],
    );
  }

  Widget _infoCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              _currencyFormatter.format(value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustoAssentoCard(double custo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.airline_seat_recline_extra_sharp, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("VALOR DE CUSTO / ASSENTO", style: TextStyle(fontSize: 10, color: Colors.white70)),
              Text(
                _currencyFormatter.format(custo),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir despesa?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("EXCLUIR", style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseItemTile extends StatelessWidget {
  final Expense item;
  final NumberFormat formatter;
  final VoidCallback onDelete;

  const _ExpenseItemTile({required this.item, required this.formatter, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white10, 
          child: Icon(Icons.receipt_long, color: Colors.white60, size: 20)
        ),
        title: Text(item.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "- ${formatter.format(item.value)}", 
              style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white24), 
              onPressed: onDelete
            ),
          ],
        ),
      ),
    );
  }
}
