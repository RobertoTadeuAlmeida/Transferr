import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/add_edit_excursion_page.dart';
import 'package:transferr/widgets/app_drawer.dart';
import 'package:transferr/widgets/excursion_card.dart';

import 'excursion_dashboard_page.dart';
import 'history_page.dart';

class ExcursionsPage extends StatefulWidget {
  const ExcursionsPage({super.key});

  @override
  State<ExcursionsPage> createState() => _ExcursionsPageState();
}

class _ExcursionsPageState extends State<ExcursionsPage> {
  bool _isSelectionMode = false;
  // CORREÇÃO 1: Padronizando o nome da variável para ser mais claro.
  final Set<String> _selectedExcursionIds = {};

  void _toggleSelection(String excursionId) {
    setState(() {
      // Usa o nome correto da variável
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
      // Usa o nome correto da variável
      _selectedExcursionIds.clear();
    });
  }

  void _confirmDeleteSelected() {
    // Usa 'context.read' pois está fora do build, em uma ação.
    final provider = context.read<ExcursionProvider>();
    // Usa o nome correto da variável
    provider.deleteMultipleExcursions(_selectedExcursionIds.toList());
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    // Usa 'context.watch' para que a UI reconstrua com mudanças nos dados.
    final excursionProvider = context.watch<ExcursionProvider>();
    final activeExcursions = excursionProvider.activeExcursions;

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed:
          _exitSelectionMode, // Botão para sair do modo de seleção
        )
            : null,
        // CORREÇÃO 2: Título dinâmico que mostra a contagem.
        title: Text(_isSelectionMode
            ? '${_selectedExcursionIds.length} selecionada(s)'
            : 'Excursões Ativas'),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Excluir Selecionadas',
              onPressed: _confirmDeleteSelected, // Botão para excluir
            )
          else
            IconButton(
              icon: const Icon(Icons.history),
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
          ? const Center(
        child: Text(
          'Nenhuma excursão ativa no momento.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: activeExcursions.length,
        itemBuilder: (context, index) {
          final excursion = activeExcursions[index];
          // CORREÇÃO 3: Define se o item está selecionado aqui.
          final isSelected =
          _selectedExcursionIds.contains(excursion.id);

          // Adiciona os gestos de clique e clique longo
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
                // Se não estiver em modo de seleção, o clique no card
                // pode levar para os detalhes (mantém a funcionalidade original)
                // Se desejar que não faça nada, remova o `else`.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExcursionDashboardPage(excursionId: excursion.id!),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                // CORREÇÃO 4: Usa a variável `isSelected` para definir a borda.
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2.0)
                    : null,
              ),
              child: ExcursionCard(excursion: excursion),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Verifica se está em modo de seleção para evitar ação indesejada
          if (!_isSelectionMode) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddEditExcursionPage(excursion: null),
              ),
            );
          }
        },
        label: const Text('Nova Excursão'),
        icon: const Icon(Icons.add),
        backgroundColor: _isSelectionMode ? Colors.grey : Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
