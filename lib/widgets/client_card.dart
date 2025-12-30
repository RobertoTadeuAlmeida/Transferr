import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 1. Importar para as cores de status

import '../models/client.dart';
import '../providers/client_provider.dart';
import '../screens/clients/add_edit_client_page.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    // 2. Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Formatadores de texto
    final phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
    final cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');

    return Dismissible(
      key: ValueKey(client.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // 3. O AlertDialog agora é 100% estilizado pelo dialogTheme
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text(
                'Tem certeza que deseja excluir "${client.name}"? Esta ação não pode ser desfeita.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  // Botão "Deletar" usa a cor de erro do tema
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // A SnackBar de erro usa a cor de erro do tema
        context.read<ClientProvider>().deleteClient(client.id).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao excluir cliente: $error'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        });
      },
      // 4. O fundo do Dismissible usa a cor de erro do tema
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      child: Card(
        // 5. O Card agora usa os estilos do cardTheme (cor, elevação, margem)
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/client_details',
              arguments: client.id,
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          // 6. Textos usam os estilos do textTheme
                          child: Text(
                            client.name,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.edit_outlined, size: 20, color: theme.primaryColor),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditClientPage(client: client),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contato: ${phoneMask.maskText(client.contact)}',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CPF: ${cpfMask.maskText(client.cpf)}',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 16,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    // 7. Cores de status usam o AppTheme
                    color: client.isActive ? AppTheme.successColor : theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardTheme.color!, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
