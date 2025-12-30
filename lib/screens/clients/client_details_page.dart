import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. IMPORTAR PARA FORMATAÇÃO DE DATA
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 2. IMPORTAR PARA CORES DE STATUS
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_client_page.dart';

class ClientDetailsPage extends StatelessWidget {
  final String clientId;

  const ClientDetailsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    // Acesso aos providers e ao tema
    final clientProvider = context.watch<ClientProvider>();
    final excursionProvider = context.watch<ExcursionProvider>();
    final client = clientProvider.getClientById(clientId);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Tela de erro, agora usando estilos do tema
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cliente não encontrado.',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Aguarde ou tente voltar e selecionar novamente.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tela principal, agora usando estilos do tema
    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Informações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informações do Cliente', style: textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildDetailRow('Nome:', client.name, context),
                    _buildDetailRow('Contato:', client.contact, context),
                    _buildDetailRow('CPF:', client.cpf, context),
                    _buildDetailRow(
                      'Nascimento:',
                      DateFormat('dd/MM/yyyy').format(client.birthDate), // Melhor formatação
                      context,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Card de Excursões
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Excursões do Cliente', style: textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    if (client.confirmedExcursionIds.isEmpty && client.pendingExcursionIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Nenhuma excursão associada a este cliente.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                    if (client.confirmedExcursionIds.isNotEmpty)
                      _buildExcursionList(
                        context,
                        title: 'Confirmadas:',
                        excursionIds: client.confirmedExcursionIds,
                        color: AppTheme.successColor, // Usando cor do tema
                        excursionProvider: excursionProvider,
                      ),
                    if (client.pendingExcursionIds.isNotEmpty)
                      _buildExcursionList(
                        context,
                        title: 'Pendentes:',
                        excursionIds: client.pendingExcursionIds,
                        color: AppTheme.warningColor, // Usando cor do tema
                        excursionProvider: excursionProvider,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Botão centralizado
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditClientPage(client: client),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Editar Cliente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares agora recebem o BuildContext para acessar o tema
  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcursionList(
      BuildContext context, {
        required String title,
        required List<String> excursionIds,
        required Color color,
        required ExcursionProvider excursionProvider,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        ...excursionIds.map((id) {
          final excursionName = excursionProvider.getExcursionById(id)?.name ?? 'Excursão não encontrada';
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    excursionName,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
