import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para os formatters
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../models/excursion.dart';
import '../../models/expense.dart'; // Importe o novo model
import '../../providers/excursion_provider.dart';
import '../excursions/add_excursion_page.dart';

class ExcursionFinancePage extends StatefulWidget {
  final Excursion excursion;

  const ExcursionFinancePage({super.key, required this.excursion});

  @override
  State<ExcursionFinancePage> createState() => _ExcursionFinancePageState();
}

class _ExcursionFinancePageState extends State<ExcursionFinancePage> {
  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.read<ExcursionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Planilha Financeira')),
      body: StreamBuilder<List<Expense>>(
        stream: excursionProvider.watchExpenses(widget.excursion.id),
        builder: (context, snapshotExpenses) {
          return StreamBuilder<double>(
            stream: excursionProvider.getTotalRevenueStream(
              widget.excursion.id,
            ),
            builder: (context, snapshotRevenue) {
              if (snapshotExpenses.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final despesas = snapshotExpenses.data ?? [];
              // Cálculo local baseado no valor da despesa
              final totalDespesas = despesas.fold<double>(
                0,
                (sum, item) => sum + item.value,
              );

              final faturamentoReal = snapshotRevenue.data ?? 0.0;

              // Usando a lógica de negócio centralizada no Model Excursion (DDD)
              final faturamentoPrevisto = widget.excursion.faturamentoPrevisto;
              final lucroPrevisto = widget.excursion.calcularLucroPrevisto(
                totalDespesas,
              );
              final lucroAtual = widget.excursion.calcularLucroAtual(
                faturamentoReal,
                totalDespesas,
              );
              final custoPorAssento = widget.excursion.calcularCustoPorAssento(
                totalDespesas,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSummaryGrid(
                            faturamentoPrevisto,
                            totalDespesas,
                            lucroPrevisto,
                            lucroAtual,
                          ),
                          const SizedBox(height: 16),
                          _buildCustoAssentoCard(custoPorAssento),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DESPESAS LANÇADAS",
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: Colors.white60),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddExpenseModal(context),
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: AppTheme.successColor,
                            ),
                            label: const Text(
                              "ADICIONAR",
                              style: TextStyle(color: AppTheme.successColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (despesas.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text("Nenhuma despesa cadastrada.")),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = despesas[index];
                          return _buildExpenseCard(item);
                        }, childCount: despesas.length),
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

  Widget _buildSummaryGrid(
    double prev,
    double desp,
    double lucroP,
    double lucroA,
  ) {
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
        _infoCard("Lucro Atual (Em Caixa)", lucroA, Colors.amber),
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
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              "R\$ ${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
          const Icon(
            Icons.airline_seat_recline_extra_sharp,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "VALOR DE CUSTO / ASSENTO",
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
              Text(
                "R\$ ${custo.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense item) {
    // Alterado para o model Expense
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(Icons.receipt_long, color: Colors.white60, size: 20),
        ),
        title: Text(item.description),
        subtitle: Text(item.category, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "- R\$ ${item.value.toStringAsFixed(2)}",
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.white24,
              ),
              onPressed: () => _confirmDelete(item.id),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir despesa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              context.read<ExcursionProvider>().deleteExpense(
                widget.excursion.id,
                expenseId,
              );
              Navigator.pop(context);
            },
            child: const Text(
              "Excluir",
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    String categoria = 'Transporte';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Nova Despesa",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Descrição com capitalização automática
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Descrição (Ex: Ônibus, Água)",
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // FILTROS DE VALOR: Teclado numérico e bloqueio de caracteres
            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
                // MESMO FILTRO DA TELA DE CADASTRO
              ],
              decoration: const InputDecoration(
                labelText: "Valor da Despesa",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: categoria,
              dropdownColor: AppTheme.cardColor,
              items: [
                'Transporte',
                'Alimentação',
                'Hospedagem',
                'Consumíveis',
                'Outros',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => categoria = v!,
              decoration: const InputDecoration(
                labelText: "Categoria",
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Converte vírgula em ponto para o parse funcionar
                  String plainValue = valorCtrl.text
                      .replaceAll('R\$', '')
                      .replaceAll('.', '')
                      .replaceAll(',', '.')
                      .trim();
                  final valor = double.tryParse(plainValue) ?? 0.0;

                  if (descCtrl.text.trim().isNotEmpty && valor > 0) {
                    context.read<ExcursionProvider>().addExpense(
                      excursionId: widget.excursion.id,
                      description: descCtrl.text.trim(),
                      value: valor,
                      category: categoria,
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Preencha a descrição e um valor válido.",
                        ),
                      ),
                    );
                  }
                },
                child: const Text("SALVAR DESPESA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
