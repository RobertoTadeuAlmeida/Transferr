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
    // Acesso ao provider e ao tema para uso futuro
    final clientProvider = context.read<ClientProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Passageiros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            // 1. O TextField agora usa o estilo global do tema.
            // Apenas definimos o que é específico para este campo.
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, CPF ou telefone...',
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

                final filteredClients = provider.clients;

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        // 2. O texto de "nenhum resultado" agora usa o tema.
                        'Nenhum passageiro encontrado.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                    ),
                  );
                }

                // O ListView.builder já usa widgets (ClientCard) que serão
                // consistentes com o tema, então nenhuma mudança é necessária aqui.
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding ajustado
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
      // 3. O FAB já herda seu estilo do floatingActionButtonTheme.
      // Nenhuma mudança de estilo é necessária.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditClientPage()),
          );
        },
        tooltip: 'Adicionar Passageiro',
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}
