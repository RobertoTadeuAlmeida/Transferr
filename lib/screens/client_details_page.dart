import 'package:flutter/material.dart';

import '../models/client.dart';

class ClientDetailsPage extends StatelessWidget {
  final Client client;

  const ClientDetailsPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Cor de fundo escura
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                      'Informações do Cliente',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Nome:', client.name),
                    _buildDetailRow('Contato:', client.contact),
                    _buildDetailRow('CPF:', client.cpf),
                    _buildDetailRow('Data de Nascimento:', '${client.birthDate.day}/${client.birthDate.month}/${client.birthDate.year}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                      'Excursões do Cliente',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    if (client.confirmedExcursionIds.isEmpty && client.pendingExcursionIds.isEmpty)
                      const Text('Nenhuma excursão associada a este cliente.', style: TextStyle(color: Colors.white70)),
                    if (client.confirmedExcursionIds.isNotEmpty)
                      _buildExcursionList('Confirmadas:', client.confirmedExcursionIds, Colors.greenAccent),
                    if (client.pendingExcursionIds.isNotEmpty)
                      _buildExcursionList('Pendentes:', client.pendingExcursionIds, Colors.amberAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar edição do cliente
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de edição de cliente em breve!')),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Cliente'),
                style: Theme.of(context).elevatedButtonTheme.style, // Usa o estilo do tema
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildExcursionList(String title, List<String> excursionIds, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        ...excursionIds.map((id) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(Icons.arrow_right, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // Em uma implementação real, você buscaria o nome da excursão pelo ID
                  'Excursão ID: $id',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}