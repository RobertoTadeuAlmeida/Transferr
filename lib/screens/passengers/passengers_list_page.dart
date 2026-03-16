import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/passenger.dart';
import '../../providers/passenger_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/passenger_card.dart';

class PassengersListPage extends StatefulWidget {
  final String excursionId;
  final bool readOnly;

  const PassengersListPage({
    super.key, 
    required this.excursionId,
    this.readOnly = false,
  });

  @override
  State<PassengersListPage> createState() => _PassengersListPageState();
}

class _PassengersListPageState extends State<PassengersListPage> {
  String _searchQuery = '';
  PassengerFilter _activeFilter = PassengerFilter.todos;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excursionProvider = context.watch<ExcursionProvider>();
    
    // OBTENÇÃO DA EMPRESA ATIVA
    final authProvider = context.watch<AuthProvider>();
    final companyId = authProvider.currentUser?.company ?? '';

    final excursion = excursionProvider.excursions.cast<dynamic>().firstWhere(
          (e) => e.id == widget.excursionId,
      orElse: () => null,
    );

    if (excursion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final excursionProviderForTap = context.read<ExcursionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Passageiros'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          _buildFilterChips(theme),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<PassengerProvider>(
              builder: (context, passengerProvider, child) {
                return StreamBuilder<List<Passenger>>(
                  // CORREÇÃO: Passando companyId para o stream
                  stream: passengerProvider.watchPassengers(widget.excursionId, companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Erro: ${snapshot.error}"));
                    }

                    final allPassengers = snapshot.data ?? [];

                    final filteredPassengers = allPassengers.where((p) {
                      final nameMatch = _normalize(p.name).contains(_normalize(_searchQuery));

                      bool categoryMatch;
                      // ESCALABILIDADE: Usa o saleValue (preço congelado) para o filtro de pendentes/confirmados
                      final double targetPrice = p.saleValue > 0 
                          ? p.saleValue 
                          : (excursion.basePrice ?? 0).toDouble();

                      switch (_activeFilter) {
                        case PassengerFilter.pendentes:
                          categoryMatch = p.depositValue < targetPrice;
                          break;
                        case PassengerFilter.confirmados:
                          categoryMatch = p.depositValue >= targetPrice;
                          break;
                        case PassengerFilter.menores:
                          categoryMatch = p.isMinor;
                          break;
                        default:
                          categoryMatch = true;
                      }
                      return nameMatch && categoryMatch;
                    }).toList();

                    if (allPassengers.isEmpty) return _buildEmptyState(theme);

                    return ListView.builder(
                      key: ValueKey('${widget.excursionId}_${_activeFilter.name}'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filteredPassengers.length,
                      itemBuilder: (context, index) {
                        final passenger = filteredPassengers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PassengerCard(
                            key: ValueKey(passenger.id),
                            passenger: passenger,
                            excursionId: widget.excursionId,
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                '/passenger-details',
                                arguments: {
                                  'passenger': passenger,
                                  'excursionId': widget.excursionId,
                                  'readOnly': widget.readOnly,
                                },
                              );
                              if (mounted && !widget.readOnly) {
                                excursionProviderForTap.syncExcursionStats(widget.excursionId);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.readOnly 
          ? null 
          : FloatingActionButton(
              onPressed: () => _showAddOptions(context, excursion.basePrice?.toDouble() ?? 0.0),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = [
      PassengerFilter.todos,
      PassengerFilter.confirmados,
      PassengerFilter.pendentes,
      PassengerFilter.menores,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _activeFilter = filter),
              backgroundColor: theme.scaffoldBackgroundColor,
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? theme.primaryColor : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Buscar passageiro...',
          prefixIcon: Icon(Icons.search, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: theme.disabledColor),
          const SizedBox(height: 16),
          const Text('Nenhum passageiro encontrado.'),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context, double basePrice) {
    final theme = Theme.of(context);
    final excursionProvider = context.read<ExcursionProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adicionar Passageiro', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add)),
                title: const Text('Novo Cadastro'),
                onTap: () async {
                  Navigator.pop(context); 
                  await Navigator.pushNamed(
                    context,
                    '/add-passenger',
                    arguments: {
                      'excursionId': widget.excursionId,
                      'excursionPrice': basePrice
                    },
                  );
                  if (mounted) {
                    excursionProvider.syncExcursionStats(widget.excursionId);
                  }
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_search)),
                title: const Text('Buscar no CRM'),
                onTap: () async {
                  Navigator.pop(context); 
                  await Navigator.pushNamed(
                    context,
                    '/global-passengers',
                    arguments: {
                      'excursionId': widget.excursionId,
                      'excursionPrice': basePrice
                    },
                  );
                  if (mounted) {
                    excursionProvider.syncExcursionStats(widget.excursionId);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
