// lib/screens/excursions/excursions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/add_edit_excursion_page.dart';

class ExcursionsPage extends StatelessWidget {
  const ExcursionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Acessa o provider para obter a lista de excursões
    final excursionProvider = context.watch<ExcursionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Excursões'),
        centerTitle: true,
      ),
      body: excursionProvider.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      )
      // 2. A LISTA DE EXCURSÕES SERÁ COLOCADA AQUI
          : ListView.builder(
        padding: const EdgeInsets.all(16.0), // Adiciona um espaçamento geral
        itemCount: excursionProvider.excursions.length,
        itemBuilder: (context, index) {
          final excursion = excursionProvider.excursions[index];

          // Usando o mesmo Card que você criou, agora no lugar certo
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
                // Abre a tela de EDIÇÃO
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddEditExcursionPage(excursion: excursion),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12.0),
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
                    const SizedBox(height: 6),
                    Text(
                      'Local: ${excursion.location}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(excursion.date)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      'Preço: R\$ ${excursion.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${excursion.availableSeats} de ${excursion.totalSeats} vagas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Chip(
                          label: Text(
                            excursion.status.name[0].toUpperCase() +
                                excursion.status.name.substring(1),
                          ),
                          backgroundColor: excursionProvider
                              .getStatusColor(excursion.status)
                              .withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: excursionProvider.getStatusColor(
                              excursion.status,
                            ),
                            fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navega para criar uma NOVA excursão (passando null)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditExcursionPage(excursion: null),
            ),
          );
        },
        label: const Text('Nova Excursão'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
