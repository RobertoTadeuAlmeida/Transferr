import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/widgets/excursion_card.dart';
import '../../models/enums.dart';
import 'excursion_dashboard_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Set para gerenciar a seleção múltipla no histórico
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
    final excursionProvider = context.watch<ExcursionProvider>();
    final theme = Theme.of(context);
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    // Filtramos apenas as que NÃO estão em andamento ou programadas
    final historyExcursions = excursionProvider.excursions
        .where(
          (e) =>
              e.status == ExcursionStatus.concluida ||
              e.status == ExcursionStatus.cancelada,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${_selectedIds.length} selecionados'
              : 'Histórico de Viagens',
        ),
        centerTitle: true,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : null,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: () async {
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed) {
                  await excursionProvider.deleteMultipleExcursions(
                    _selectedIds.toList(),
                  );
                  setState(() => _selectedIds.clear());
                }
              },
            ),
        ],
      ),
      body: excursionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyExcursions.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyExcursions.length,
              itemBuilder: (context, index) {
                final excursion = historyExcursions[index];
                final isSelected = _selectedIds.contains(excursion.id);

                return ExcursionCard(
                  excursion: excursion,
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelectionMode) {
                      _toggleSelection(excursion.id);
                    } else {
                      // Navega para o dashboard em modo de visualização
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
                );
              },
            ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir do Histórico?'),
            content: const Text(
              'Esta ação é permanente e removerá todos os registros desta viagem.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'EXCLUIR',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'Nenhuma viagem finalizada ainda.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
