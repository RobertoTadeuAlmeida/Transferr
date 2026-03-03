import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/add_excursion_page.dart';
import 'package:transferr/widgets/app_drawer.dart';
import 'package:transferr/screens/excursions/widgets/excursion_card.dart';
import 'excursion_dashboard_page.dart';

class ExcursionsPage extends StatefulWidget {
  const ExcursionsPage({super.key});

  @override
  State<ExcursionsPage> createState() => _ExcursionsPageState();
}

class _ExcursionsPageState extends State<ExcursionsPage> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para que a tela inteira reconstrua quando o Firestore mudar
    final excursionProvider = context.watch<ExcursionProvider>();
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      drawer: isSelectionMode ? null : const AppDrawer(),
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _selectedIds.clear()),
        )
            : null,
        title: Text(isSelectionMode
            ? '${_selectedIds.length} selecionados'
            : 'Minhas Viagens'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  await excursionProvider.deleteMultipleExcursions(_selectedIds.toList());
                  setState(() => _selectedIds.clear());
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExcursionPage())),
            ),
        ],
      ),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator()) // Feedback de carregamento
          : excursionProvider.excursions.isEmpty
          ? const Center(child: Text("Nenhuma excursão encontrada."))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: excursionProvider.excursions.length,
        itemBuilder: (context, index) {
          final excursion = excursionProvider.excursions[index];
          final isSelected = _selectedIds.contains(excursion.id);

          return ExcursionCard(
            // IMPORTANTE: A ValueKey força o Flutter a redesenhar o Card
            // se o número de reservas mudar no Firebase.
            key: ValueKey('${excursion.id}_${excursion.reservedSeats}'),
            excursion: excursion,
            isSelected: isSelected,
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(excursion.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExcursionDashboardPage(
                      excursionId: excursion.id,
                    ),
                  ),
                );
              }
            },
            onLongPress: () {
              _toggleSelection(excursion.id);
            },
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Excursões?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}