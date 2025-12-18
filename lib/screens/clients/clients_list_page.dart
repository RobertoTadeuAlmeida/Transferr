import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/widgets/app_drawer.dart';

import '../../providers/client_provider.dart';
import '../../widgets/client_card.dart';
import 'add_edit_client_page.dart';

class ClientsListPage extends StatelessWidget {
  const ClientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.read<ClientProvider>();

    return Scaffold(

      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Passageiros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nome, CPF ou telefone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: (value) {
                // A ação de chamar o provider continua a mesma.
                clientProvider.searchClients(value);
              },
            ),
          ),
          // 2. Envolva a parte que precisa ser reconstruída com um Consumer.
          Expanded(
            // O Consumer escuta o ClientProvider e reconstrói seu 'builder'
            // sempre que notifyListeners() é chamado.
            child: Consumer<ClientProvider>(
              builder: (context, provider, child) {
                // O 'provider' aqui é a instância atualizada do ClientProvider.
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredClients = provider.clients;

                if (filteredClients.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum cliente encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ClientCard(client: client);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditClientPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
