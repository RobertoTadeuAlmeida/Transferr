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
    // Acesso aos providers e ao tema
    final clientProvider = context.watch<ClientProvider>();
    final excursionProvider = context.read<ExcursionProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Passageiro'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            // 1. TextField usa o estilo global do tema
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
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
                  return Center(
                    // 2. Texto de status usa o tema
                    child: Text(
                      'Nenhum cliente encontrado.',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: provider.clients.length,
                  itemBuilder: (ctx, index) {
                    final client = provider.clients[index];

                    // 3. ListTile e CircleAvatar usam cores do tema
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.2),
                        foregroundColor: colorScheme.primary,
                        child: Text(
                          client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(client.name, style: textTheme.bodyLarge),
                      subtitle: Text(
                        'CPF: ${client.cpf}',
                        style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      onTap: () {
                        // A chamada para o AlertDialog permanece a mesma,
                        // mas agora ele será estilizado pelo tema.
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

  void _addPassenger(BuildContext context, ExcursionProvider excursionProvider, Client client) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Passageiro'),
        content: Text('Deseja adicionar "${client.name}" a esta excursão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            // Os TextButtons já herdam o estilo do tema
            child: const Text('Cancelar'),
          ),
          // 4. O botão de confirmação agora usa o estilo do ElevatedButtonTheme
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await excursionProvider.addParticipantToExcursion(
        excursionId: excursionId,
        client: client,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // 5. SnackBar de erro usa a cor de erro do tema
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
