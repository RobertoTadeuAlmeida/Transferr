import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/excursion_provider.dart';

class AddPassengerPage extends StatelessWidget {
  final String excursionId;

  const AddPassengerPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    // Usamos 'watch' para que a UI se reconstrua ao buscar,
    // e 'read' para chamar a ação de adicionar.
    final clientProvider = context.watch<ClientProvider>();
    final excursionProvider = context.read<ExcursionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Passageiro'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar cliente por nome, CPF ou telefone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                // Reutilizamos a função de busca que já existe no ClientProvider!
                clientProvider.searchClients(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.clients.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.'));
                }

                return ListView.builder(
                  itemCount: provider.clients.length,
                  itemBuilder: (ctx, index) {
                    final client = provider.clients[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(client.name.isNotEmpty ? client.name[0] : '?'),
                      ),
                      title: Text(client.name),
                      subtitle: Text('CPF: ${client.cpf}'),
                      // Ação ao tocar em um cliente da lista
                      onTap: () async {
                        _addPassenger(context, excursionProvider, client);

                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Função para adicionar o passageiro e tratar o resultado
  void _addPassenger(BuildContext context, ExcursionProvider excursionProvider, Client client) async {
    // Exibe um diálogo de confirmação
    bool? confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Passageiro'),
        content: Text('Deseja adicionar "${client.name}" a esta excursão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    // Se o usuário não confirmou, não faz nada
    if (confirmed != true) {
      return;
    }

    try {
      await excursionProvider.addParticipantToExcursion(
        excursionId: excursionId,
        client: client,
      );

      // Se a adição foi bem-sucedida, volta para a tela anterior
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Mostra uma mensagem de erro se algo der errado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar passageiro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
