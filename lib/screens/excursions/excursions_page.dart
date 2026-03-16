import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/screens/excursions/add_excursion_page.dart';
import 'package:transferr/widgets/app_drawer.dart';
import 'package:transferr/screens/excursions/widgets/excursion_card.dart';
import '../../models/enums.dart';
import '../../config/theme/app_theme.dart';
import 'excursion_dashboard_page.dart';

class ExcursionsPage extends StatefulWidget {
  const ExcursionsPage({super.key});

  @override
  State<ExcursionsPage> createState() => _ExcursionsPageState();
}

class _ExcursionsPageState extends State<ExcursionsPage> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  ExcursionStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.watch<ExcursionProvider>();
    final bool isSelectionMode = _selectedIds.isNotEmpty;
    final theme = Theme.of(context);

    // Lógica de Filtragem
    final filteredExcursions = excursionProvider.excursions.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           e.idMainDestination.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == null || e.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

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
      body: Column(
        children: [
          _buildSearchAndFilter(theme),
          Expanded(
            child: excursionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExcursions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filteredExcursions.length,
              itemBuilder: (context, index) {
                final excursion = filteredExcursions[index];
                final isSelected = _selectedIds.contains(excursion.id);

                return ExcursionCard(
                  key: ValueKey('${excursion.id}_${excursion.reservedSeats}_${excursion.status}'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou destino...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ) 
                : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('Todas', null, theme),
                const SizedBox(width: 8),
                _buildStatusChip('Programadas', ExcursionStatus.programada, theme),
                const SizedBox(width: 8),
                _buildStatusChip('Ativas', ExcursionStatus.emAndamento, theme),
                const SizedBox(width: 8),
                _buildStatusChip('Concluídas', ExcursionStatus.concluida, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, ExcursionStatus? status, ThemeData theme) {
    final isSelected = _statusFilter == status;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onSelected: (bool selected) {
        setState(() => _statusFilter = selected ? status : null);
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? "Nenhuma excursão cadastrada." : "Nenhuma viagem encontrada para esta busca.",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Excursões?'),
        content: const Text('Esta ação não pode ser desfeita e removerá todos os dados das viagens selecionadas.'),
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
