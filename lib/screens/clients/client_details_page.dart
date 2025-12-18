import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_client_page.dart';

class ClientDetailsPage extends StatelessWidget {
  final String clientId;

  const ClientDetailsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    // 3. [MUDANÇA] Busca o cliente e as excursões usando os Providers.
    final clientProvider = context.watch<ClientProvider>();
    final excursionProvider = context.watch<ExcursionProvider>();

    // Usa o ID para encontrar o objeto Client completo na lista do provider.
    final client = clientProvider.getClientById(clientId);

    // 4. [MUDANÇA] Adiciona tratamento para casos de erro (cliente não encontrado).
    if (client == null) {
      // Isso pode acontecer se a lista de clientes ainda estiver carregando
      // ou se o ID for inválido por algum motivo.
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cliente não encontrado.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Aguarde ou tente voltar e selecionar novamente.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // O resto da sua UI continua igual, usando a variável 'client' que acabamos de buscar.
    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações do Cliente',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Nome:', client.name),
                    _buildDetailRow('Contato:', client.contact),
                    _buildDetailRow('CPF:', client.cpf),
                    _buildDetailRow(
                      'Data de Nascimento:',
                      '${client.birthDate.day}/${client.birthDate.month}/${client.birthDate.year}',
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
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excursões do Cliente',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 5. [MELHORIA] Usa o ExcursionProvider para mostrar o nome real das excursões.
                    if (client.confirmedExcursionIds.isEmpty &&
                        client.pendingExcursionIds.isEmpty)
                      const Text(
                        'Nenhuma excursão associada a este cliente.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    if (client.confirmedExcursionIds.isNotEmpty)
                      _buildExcursionList(
                        'Confirmadas:',
                        client.confirmedExcursionIds,
                        Colors.greenAccent,
                        excursionProvider, // Passa o provider como argumento
                      ),
                    if (client.pendingExcursionIds.isNotEmpty)
                      _buildExcursionList(
                        'Pendentes:',
                        client.pendingExcursionIds,
                        Colors.amberAccent,
                        excursionProvider, // Passa o provider como argumento
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                icon: const Icon(Icons.edit),
                label: const Text('Editar Cliente'),
                style: Theme.of(context).elevatedButtonTheme.style,
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

  // 6. [MUDANÇA] O método agora recebe o ExcursionProvider para buscar os nomes.
  Widget _buildExcursionList(
    String title,
    List<String> excursionIds,
    Color color,
    ExcursionProvider excursionProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        ...excursionIds.map((id) {
          // Busca o nome da excursão usando o ID.
          final excursionName =
              excursionProvider.getExcursionById(id)?.name ??
              'Excursão não encontrada';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    excursionName, // Mostra o nome real.
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
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
