import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/excursion_provider.dart';import '../../widgets/excursion_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Set<String> _selectedIds = {};

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _deleteSelectedItems() {
    final provider = context.read<ExcursionProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Excluir permanentemente os ${_selectedIds.length} itens selecionados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              provider.deleteMultipleExcursions(_selectedIds.toList()).then((_) => _clearSelection());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final historicalExcursions = excursionProvider.historicalExcursions;
    final hasSelection = _selectedIds.isNotEmpty;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: hasSelection
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
          tooltip: 'Cancelar Seleção',
        )
            : null,
        title: Text(hasSelection ? '${_selectedIds.length} selecionada(s)' : 'Histórico'),
        centerTitle: true,
        actions: [
          if (hasSelection)
            IconButton(
              icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              tooltip: 'Excluir Selecionados',
              onPressed: _deleteSelectedItems,
            )
          else if (historicalExcursions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar Histórico',
              onPressed: () => _showClearHistoryConfirmationDialog(context, excursionProvider),
            ),
        ],
      ),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historicalExcursions.isEmpty
          ? Center(
        child: Text(
          'O histórico de excursões está vazio.',
          style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        itemCount: historicalExcursions.length,
        itemBuilder: (context, index) {
          final excursion = historicalExcursions[index];
          final isSelected = _selectedIds.contains(excursion.id);

          return Dismissible(
            key: ValueKey(excursion.id!),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              context.read<ExcursionProvider>().deleteExcursion(excursion.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${excursion.name} removida.'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            background: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha(100),
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.only(right: 20.0),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            ),
            child: Card(
              // O Card externo agora só controla a borda e a margem
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: isSelected
                    ? BorderSide(color: theme.primaryColor, width: 2.0)
                    : BorderSide.none,
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(excursion.id!);
                    } else {
                      _selectedIds.add(excursion.id!);
                    }
                  });
                },
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
                title: ExcursionCard(
                  excursion: excursion,
                  showFeaturedStar: false,
                  actionsEnabled: false,
                  isInsideListTile: true, // Crucial: informa ao card para não renderizar seu próprio 'Card'
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// A função _showClearHistoryConfirmationDialog não precisa de alterações
void _showClearHistoryConfirmationDialog(BuildContext context, ExcursionProvider provider) {
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
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              provider.clearHistory();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      );
    },
  );
}
