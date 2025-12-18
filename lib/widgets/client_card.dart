import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../providers/client_provider.dart';
import '../screens/clients/add_edit_client_page.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
    final cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');

    return Dismissible(
      key: ValueKey(client.id),
      direction: DismissDirection.endToStart,
      // Apenas da direita para a esquerda.
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text(
                'Tem certeza que deseja deletar "${client.name}"? Esta ação não pode ser desfeita.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  // Não deleta
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  // Sim, deleta
                  child: const Text(
                    'Deletar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },

      // Ação executada APÓS a confirmação.
      onDismissed: (direction) {
        // 3. CHAMA O MÉTODO DO PROVIDER PARA DELETAR
        context.read<ClientProvider>().deleteClient(client.id).catchError((
          error,
        ) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao deletar cliente: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      },

      // O fundo que aparece enquanto o card está sendo deslizado.
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      // O seu Card original agora é o filho do Dismissible.
      child: Stack(
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/client_details',
                  arguments: client.id,
                );
                print('Card do cliente ${client.name} clicado.');
              },
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditClientPage(client: client),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Contato: ${phoneMask.maskText(client.contact)}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CPF: ${cpfMask.maskText(client.cpf)}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: client.isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
