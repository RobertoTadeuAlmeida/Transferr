import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String userId = ''; // Variável para armazenar o ID do usuário autenticado.

  double totalGrossRevenue = 0.0;
  double totalNetRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    // Obtém o ID do usuário autenticado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
    }
    _loadFinanceData();
  }

  // Função para carregar os dados financeiros de todas as excursões
  Future<void> _loadFinanceData() async {
    try {
      // Busca todas as excursões
      final querySnapshot = await _firestore.collection('artifacts')
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

      setState(() {
        totalGrossRevenue = calculatedGross;
        totalNetRevenue = calculatedNet;
      });
    } catch (e) {
      print("Erro ao carregar dados financeiros: $e");
      // Opcional: mostrar um SnackBar ou diálogo de erro ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar finanças: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Administração Financeira'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Cor de fundo escura
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              color: Theme.of(context).cardColor, // Usa a cor do cartão do tema
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo Financeiro da Empresa',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildFinancialSummaryRow(
                      'Renda Bruta Total:',
                      'R\$ ${totalGrossRevenue.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                    const SizedBox(height: 10),
                    _buildFinancialSummaryRow(
                      'Renda Líquida Total Estimada:',
                      'R\$ ${totalNetRevenue.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Estes valores são calculados a partir da soma da renda bruta e líquida de todas as excursões. Para detalhes por excursão, verifique a tela de Excursões.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadFinanceData, // Recarrega os dados financeiros
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar Dados Financeiros'),
                style: Theme.of(context).elevatedButtonTheme.style, // Usa o estilo do tema
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}