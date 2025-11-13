import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/excursion.dart';
import '../../models/participant.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_excursion_page.dart';

class ExcursionDetailsPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDetailsPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final Excursion? excursion = context
        .watch<ExcursionProvider>()
        .getExcursionById(excursionId);

    if (excursion == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Erro')),
        body: const Center(child: Text('Excursão não encontrada.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(excursion.name),
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor, // Usa a cor de fundo do tema
        foregroundColor: Colors.white, // Texto branco
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Theme.of(context).cardColor, // Usa a cor do cartão do tema
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalhes da Excursão',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Descrição:', excursion.description),
                    _buildDetailRow(
                      'Data:',
                      '${excursion.date.day}/${excursion.date.month}/${excursion.date.year}',
                    ),
                    _buildDetailRow(
                      'Preço por Cliente:',
                      'R\$ ${excursion.price.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow('Status:', excursion.status.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Theme.of(context).cardColor, // Usa a cor do cartão do tema
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo Financeiro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFinancialRow(
                      'Total de Clientes Confirmados:',
                      '${excursion.totalClientsConfirmed}',
                    ),
                    _buildFinancialRow(
                      'Renda Bruta:',
                      'R\$ ${excursion.grossRevenue.toStringAsFixed(2)}',
                    ),
                    _buildFinancialRow(
                      'Renda Líquida Estimada:',
                      'R\$ ${excursion.netRevenue.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Theme.of(context).cardColor, // Usa a cor do cartão do tema
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Excurção',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // TODO: Implementar funcionalidade para adicionar/gerenciar participantes
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddEditExcursionPage(
                                  excursion: excursion,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (excursion.participants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Nenhum participante cadastrado para esta excursão.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ...excursion.participants.map((participant) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                participant.status ==
                                        ParticipantStatus.confirmed
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color:
                                    participant.status ==
                                        ParticipantStatus.confirmed
                                    ? Colors.greenAccent
                                    : Colors.amberAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${participant.clientName} (${participant.status})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // TODO: Navegar para os detalhes do cliente
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Ver detalhes de ${participant.clientName} em breve!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar edição da excursão
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade de edição em breve!'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Excursão'),
                style: Theme.of(
                  context,
                ).elevatedButtonTheme.style, // Usa o estilo do tema
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
