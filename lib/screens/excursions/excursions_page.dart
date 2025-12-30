import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/add_edit_excursion_page.dart';
import 'package:transferr/widgets/app_drawer.dart';
import 'package:transferr/widgets/excursion_card.dart'; // Importa o widget correto

import 'excursion_dashboard_page.dart';
import 'history_page.dart';

class ExcursionsPage extends StatefulWidget {
  const ExcursionsPage({super.key});

  @override
  State<ExcursionsPage> createState() => _ExcursionsPageState();
}

class _ExcursionsPageState extends State<ExcursionsPage> {
  // Lógica de estado para o modo de seleção
  bool _isSelectionMode = false;
  final Set<String> _selectedExcursionIds = {};

  void _toggleSelection(String excursionId) {
    setState(() {
      if (_selectedExcursionIds.contains(excursionId)) {
        _selectedExcursionIds.remove(excursionId);
        if (_selectedExcursionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedExcursionIds.add(excursionId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedExcursionIds.clear();
    });
  }

  // Mostra um diálogo de confirmação antes de excluir
  void _onDeletePressed() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir as ${_selectedExcursionIds.length} excursões selecionadas? Esta ação não pode ser desfeita.'),
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
              final provider = context.read<ExcursionProvider>();
              provider.deleteMultipleExcursions(_selectedExcursionIds.toList());
              Navigator.of(dialogContext).pop();
              _exitSelectionMode();
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
    final activeExcursions = excursionProvider.activeExcursions;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
          tooltip: 'Sair da seleção',
        )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedExcursionIds.length} selecionada(s)'
              : 'Excursões Ativas',
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              tooltip: 'Excluir Selecionadas',
              onPressed: _onDeletePressed,
            )
          else
            IconButton(
              icon: const Icon(Icons.history_edu_outlined),
              tooltip: 'Histórico de Excursões',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
        ],
      ),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeExcursions.isEmpty
          ? Center(
        child: Text(
          'Nenhuma excursão ativa no momento.',
          style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: activeExcursions.length,
        itemBuilder: (context, index) {
          final excursion = activeExcursions[index];
          final isSelected = _selectedExcursionIds.contains(excursion.id);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _toggleSelection(excursion.id!);
              });
            },
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(excursion.id!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExcursionDashboardPage(excursionId: excursion.id!),
                  ),
                );
              }
            },
            // O ExcursionCard agora desenha sua própria borda
            child: ExcursionCard(
              excursion: excursion,
              isSelected: isSelected, // Passa o estado de seleção
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isSelectionMode) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddEditExcursionPage()),
            );
          }
        },
        label: const Text('Nova Excursão'),
        icon: const Icon(Icons.add),
        backgroundColor: _isSelectionMode ? Colors.grey.shade700 : theme.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
