// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import necessário para formatação de data
import 'package:provider/provider.dart';
import 'package:transferr/screens/clients_list_page.dart';
import '../providers/excursion_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transferr/screens/excursions_page.dart';
import 'package:transferr/screens/finance_page.dart';

import 'excursions/add_edit_excursion_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. OBTÉM O PROVIDER
    // "Watch" para que a UI se reconstrua automaticamente quando os dados mudarem.
    final excursionProvider = context.watch<ExcursionProvider>();

    // 2. CÁLCULOS LEVES E INSTANTÂNEOS
    // A lógica pesada foi removida. Estes cálculos agora são simples divisões.
    final double paymentsPercentage = excursionProvider.totalPayments > 0
        ? (excursionProvider.completePayments / excursionProvider.totalPayments)
        : 0.0;

    final double seatsPercentage =
        excursionProvider.totalSeatsOfAllExcursions > 0
        ? (excursionProvider.totalClientsConfirmed /
              excursionProvider.totalSeatsOfAllExcursions)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildAppDrawer(context),
      // UI do Drawer movida para um método limpo
      body: excursionProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DASHBOARD DE MÉTRICAS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashboardCard(
                          'Pagamentos',
                          '${(paymentsPercentage * 100).toStringAsFixed(0)}%',
                          paymentsPercentage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashboardCard(
                          'Assentos Ocupados',
                          // CORRIGIDO: Usa os getters pré-calculados do provider.
                          '${excursionProvider.totalClientsConfirmed}/${excursionProvider.totalSeatsOfAllExcursions}',
                          seatsPercentage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- RESUMO FINANCEIRO ---
                  _buildFinancialSummaryCard(excursionProvider),

                  const SizedBox(height: 30),

                  // 3. LISTA DE PRÓXIMAS EXCURSÕES (REATIVADA)
                  if (excursionProvider.excursions.isNotEmpty) ...[
                    Text(
                      'Próximas Excursões',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Mostra no máximo as próximas 5 excursões para um dashboard limpo
                      itemCount: excursionProvider.excursions.length > 5
                          ? 5
                          : excursionProvider.excursions.length,
                      itemBuilder: (context, index) {
                        final excursion = excursionProvider.excursions[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          color: const Color(0xFF2A2A2A),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/excursion_details',
                                arguments: excursion.id,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    excursion.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      // 4. CORREÇÃO: Formatação de data profissional
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(excursion.date),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        excursion.location,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navega para a tela de criação de excursão.
          // Não passamos uma excursão, então a tela saberá que é para criar uma nova.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditExcursionPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFFF97316),
        // Cor do tema
        foregroundColor: Colors.white,
        // Cor do ícone
        tooltip: 'Adicionar Nova Excursão',
        // Texto de ajuda
        child: const Icon(Icons.add),
      ),
    );
  }

  // 5. ORGANIZAÇÃO: Todos os métodos de construção de widgets ficam agrupados aqui.

  /// Constrói o menu lateral (Drawer) da aplicação.
  Drawer _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF97316)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Não autenticado',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.tour, color: Colors.white),
            title: const Text(
              'Lista de Excursões',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExcursionsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text(
              'Clientes',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientsListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.white),
            title: const Text(
              'Finanças',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancePage()),
              );
            },
          ),
          const Divider(color: Colors.white38),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Sair', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  /// Constrói o card de resumo financeiro.
  Card _buildFinancialSummaryCard(ExcursionProvider excursionProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            _buildFinancialSummaryRow(
              'Renda Bruta',
              'R\$ ${excursionProvider.totalGrossRevenue.toStringAsFixed(2)}',
              Colors.greenAccent,
            ),
            const SizedBox(height: 10),
            _buildFinancialSummaryRow(
              'Renda Líquida',
              'R\$ ${excursionProvider.totalNetRevenue.toStringAsFixed(2)}',
              Colors.lightGreen,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um card de métrica para o dashboard.
  Widget _buildDashboardCard(String title, String value, double percentage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma linha de informação para o resumo financeiro.
  Widget _buildFinancialSummaryRow(
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
