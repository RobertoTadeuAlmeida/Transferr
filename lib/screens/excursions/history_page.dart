import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/excursion_provider.dart';
import '../../widgets/excursion_card.dart'; // Vamos reutilizar o card!

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Set<String> _selectedIds = {};

  // Método para limpar a seleção
  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  // Método para confirmar e excluir os itens selecionados
  void _deleteSelectedItems() {
    final provider = context.read<ExcursionProvider>();
    provider.deleteMultipleExcursions(_selectedIds.toList()).then((_) {
      _clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Apenas "assiste" o provider
    final excursionProvider = context.watch<ExcursionProvider>();
    final historicalExcursions = excursionProvider.historicalExcursions;
    final bool hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: hasSelection
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
                tooltip: 'Cancelar Seleção',
              )
            : null,
        title: Text(
          hasSelection
              ? '${_selectedIds.length} selecionada(s)'
              : 'Histórico de Excursões',
        ),
        centerTitle: true,
        actions: [
          if (hasSelection)
            // Botão para excluir os itens selecionados
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Excluir Selecionados',
              onPressed: _deleteSelectedItems,
            )
          else if (historicalExcursions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar Histórico',
              onPressed: () {
                _showClearHistoryConfirmationDialog(context, excursionProvider);
              },
            ),
        ],
      ),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historicalExcursions.isEmpty
          ? const Center(
              child: Text(
                'O histórico de excursões está vazio.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: historicalExcursions.length,
              itemBuilder: (context, index) {
                final excursion = excursionProvider.historicalExcursions[index];
                final isSelected = _selectedIds.contains(excursion.id);

                return Dismissible(
                  key: ValueKey(excursion.id!),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    context.read<ExcursionProvider>().deleteExcursion(
                      excursion.id!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${excursion.name} removida.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red.withOpacity(0.5),
                    padding: const EdgeInsets.only(right: 20.0),

                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    // Adiciona cor se estiver selecionado para melhor feedback
                    color: isSelected
                        ? const Color(0xFF333A44)
                        : const Color(0xFF2A2A2A),
                    elevation: isSelected ? 4 : 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: isSelected
                          ? const BorderSide(color: Colors.blue, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 12),
                      // O Checkbox fica à esquerda
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(excursion.id!);
                            } else {
                              _selectedIds.remove(excursion.id!);
                            }
                          });
                        },
                      ),
                      // O título do ListTile é o nosso Card (sem o Card externo)
                      title: ExcursionCard(
                        excursion: excursion,
                        showFeaturedStar: false,
                        actionsEnabled: false,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

void _showClearHistoryConfirmationDialog(
  BuildContext context,
  ExcursionProvider provider,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Limpar Histórico?'),
        content: const Text(
          'Esta ação é irreversível e excluirá permanentemente todas as excursões concluídas e canceladas. Deseja continuar?',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Fecha o diálogo
            },
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearHistory();
              Navigator.of(dialogContext).pop(); // Fecha o diálogo
            },
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      );
    },
  );
}
