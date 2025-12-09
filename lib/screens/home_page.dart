import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/excursion_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'excursions/add_edit_excursion_page.dart';
import 'package:transferr/screens/excursions_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // "Watch" o provider para reconstruir a UI quando os dados mudam
    final excursionProvider = context.watch<ExcursionProvider>();

    // Calcula as porcentagens
    double paymentsPercentage = excursionProvider.totalPayments > 0
        ? (excursionProvider.completePayments / excursionProvider.totalPayments)
        : 0.0;
    // Calcula o total de assentos de todas as excursões
    int totalSeatsOfAllExcursions = excursionProvider.excursions.fold(
      0,
      (sum, excursion) => sum + excursion.totalSeats,
    );
    // Calcula a porcentagem de assentos disponíveis
    double seatsPercentage = totalSeatsOfAllExcursions > 0
        ? (excursionProvider.totalClientsConfirmed / totalSeatsOfAllExcursions)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Excursões'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [],
      ),
      drawer: Drawer(
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
                    FirebaseAuth.instance.currentUser?.displayName ??
                        FirebaseAuth.instance.currentUser?.email
                            ?.split('@')
                            ?.first ??
                        'Usuário',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Exibe o e-mail completo do usuário
                    FirebaseAuth.instance.currentUser?.email ??
                        'Não autenticado',
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
              onTap: () {
                // Ação para o Dashboard (atualmente, apenas fecha o drawer)
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tour, color: Colors.white),
              title: const Text(
                'Lista de Excursões',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                //Fechar o menu antes de navegar
                Navigator.pop(context);
                //Navegar para proxima tela
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExcursionsPage(),
                  ),
                );
              },
            ),
            // --- INÍCIO DOS NOVOS LISTTILES ---
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text(
                'Clientes',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // TODO: Navegar para a tela de Clientes
                // Ex: Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsPage()));
                print('Navegar para Clientes');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.white),
              title: const Text(
                'Finanças',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // TODO: Navegar para a tela de Finanças
                // Ex: Navigator.push(context, MaterialPageRoute(builder: (context) => const FinancePage()));
                print('Navegar para Finanças');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Configurações',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // TODO: Navegar para a tela de Configurações
                // Ex: Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                print('Navegar para Configurações');
                Navigator.pop(context);
              },
            ),
            // --- FIM DOS NOVOS LISTTILES ---
            const Divider(color: Colors.white38),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Sair', style: TextStyle(color: Colors.white)),
              onTap: () async {
                // LÓGICA PARA FAZER LOG OUT
                await FirebaseAuth.instance.signOut();
                // O AuthWrapper cuidará de redirecionar para a LoginPage.
              },
            ),
          ],
        ),
      ),
      body: excursionProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashboardCard(
                          context,
                          'Pagamentos completos',
                          '${(paymentsPercentage * 100).toStringAsFixed(0)}%',
                          paymentsPercentage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDashboardCard(
                          context,
                          'Assentos Ocupados',
                          '${excursionProvider.totalClientsConfirmed}/${totalSeatsOfAllExcursions}',
                          seatsPercentage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo Financeiro da Empresa',
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
                            Colors.white,
                          ),
                          const SizedBox(height: 10),
                          _buildFinancialSummaryRow(
                            'Renda Líquida',
                            'R\$ ${excursionProvider.totalNetRevenue.toStringAsFixed(2)}',
                            Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // const SizedBox(height: 30),
                  // Text(
                  //   'Próximas Excursões',
                  //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
                  // // Usa a lista de excursões diretamente do provider
                  // ListView.builder(
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   itemCount: excursionProvider.excursions.length,
                  //   itemBuilder: (context, index) {
                  //     final excursion = excursionProvider.excursions[index];
                  //     return Card(
                  //       elevation: 2,
                  //       margin: const EdgeInsets.symmetric(vertical: 8.0),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12.0),
                  //       ),
                  //       color: const Color(0xFF2A2A2A),
                  //       clipBehavior: Clip.antiAlias,
                  //       child: InkWell(
                  //         onTap: () {
                  //           print(
                  //             'CLICOU!!! Navegando para detalhes da excursão com ID: ${excursion.id}',
                  //           );
                  //           Navigator.pushNamed(
                  //             context,
                  //             '/excursion_details',
                  //             arguments: excursion.id,
                  //           );
                  //         },
                  //         borderRadius: BorderRadius.circular(12.0),
                  //         child: Padding(
                  //           padding: const EdgeInsets.all(16.0),
                  //           child: Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 excursion.name,
                  //                 style: const TextStyle(
                  //                   fontSize: 18,
                  //                   fontWeight: FontWeight.bold,
                  //                   color: Colors.white,
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 6),
                  //               Text(
                  //                 'Data: ${excursion.date.day}/${excursion.date.month}/${excursion.date.year}',
                  //                 style: TextStyle(
                  //                   fontSize: 14,
                  //                   color: Colors.grey[400],
                  //                 ),
                  //               ),
                  //               Text(
                  //                 'Preço: R\$ ${excursion.price.toStringAsFixed(2)}',
                  //                 style: TextStyle(
                  //                   fontSize: 14,
                  //                   color: Colors.grey[400],
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 8),
                  //               Align(
                  //                 alignment: Alignment.bottomRight,
                  //                 child: Chip(
                  //                   label: Text(
                  //                     excursion.status.name[0].toUpperCase() +
                  //                         excursion.status.name.substring(1),
                  //                   ),
                  //                   backgroundColor: excursionProvider
                  //                       .getStatusColor(excursion.status)
                  //                       .withOpacity(0.2),
                  //                   labelStyle: TextStyle(
                  //                     color: excursionProvider.getStatusColor(
                  //                       excursion.status,
                  //                     ),
                  //                     fontWeight: FontWeight.bold,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),

    );
  }

  // O resto dos widgets de construção permanecem os mesmos
  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String value,
    double percentage,
  ) {
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
