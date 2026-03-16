import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/passenger.dart';
import '../../providers/auth_provider.dart'; // Import necessário
import '../../providers/excursion_provider.dart';
import '../../providers/passenger_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/passenger_crm_card.dart';
import '../../config/theme/app_theme.dart';

class GlobalPassengersPage extends StatefulWidget {
  final String? excursionId;
  final double? excursionPrice;

  const GlobalPassengersPage({
    super.key,
    this.excursionId,
    this.excursionPrice,
  });

  @override
  State<GlobalPassengersPage> createState() => _GlobalPassengersPageState();
}

class _GlobalPassengersPageState extends State<GlobalPassengersPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionMode = widget.excursionId != null;
    
    // OBTENÇÃO DA EMPRESA ATIVA PARA O MULTI-TENANT
    final authProvider = context.watch<AuthProvider>();
    final companyId = authProvider.currentUser?.company ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          isSelectionMode ? 'Selecionar Passageiro' : 'Base de Clientes',
        ),
        centerTitle: true,
      ),
      drawer: isSelectionMode ? null : const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: companyId.isEmpty 
              ? const Center(child: Text("Nenhuma empresa ativa selecionada."))
              : StreamBuilder<List<Passenger>>(
                  stream: context.read<PassengerProvider>().getGlobalPassengersStream(companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(theme, snapshot.error.toString());
                    }

                    final allPassengers = snapshot.data ?? [];

                    if (allPassengers.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    final filtered = allPassengers.where((p) {
                      final search = _normalize(_searchQuery);
                      final nameMatch = _normalize(p.name).contains(search);
                      final docMatch = p.document.contains(_searchQuery);
                      return nameMatch || docMatch;
                    }).toList();

                    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final passenger = filtered[index];

                        return PassengerCrmCard(
                          passenger: passenger,
                          onTap: () {
                            if (isSelectionMode) {
                              _showConfirmationDialog(context, passenger);
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/passenger-details',
                                arguments: {'passenger': passenger},
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, Passenger passenger) {
    final passengerProvider = context.read<PassengerProvider>();
    final excursionProvider = context.read<ExcursionProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Vincular Passageiro'),
          content: Text(
            'Deseja adicionar "${passenger.name}" a esta excursão? Você será levado para a tela de edição em seguida.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
              onPressed: () async {
                try {
                  final excursion = excursionProvider.excursions.firstWhere(
                    (e) => e.id == widget.excursionId,
                  );
                  
                  final success = await passengerProvider.linkExistingPassenger(
                    context: context,
                    passengerId: passenger.id,
                    excursionId: widget.excursionId!,
                    depositValue: 0.0,
                    totalValue: excursion.basePrice,
                  );

                  if (success) {
                    await excursionProvider.syncExcursionStats(
                      widget.excursionId!,
                    );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("${passenger.name} vinculado!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      final updatedPassenger = passenger.copyWith(
                        excursionId: widget.excursionId,
                      );

                      navigator.pushReplacementNamed(
                        '/add-passenger',
                        arguments: {
                          'passenger': updatedPassenger,
                          'excursionId': widget.excursionId,
                          'excursionPrice': excursion.basePrice, // Importante passar o preço aqui também
                        },
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("Erro ao vincular: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou documento...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhum passageiro cadastrado.'
                : 'Nenhum resultado para "$_searchQuery"',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Erro ao carregar dados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
