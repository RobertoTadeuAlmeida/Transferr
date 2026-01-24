import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/passenger.dart';
import '../../providers/passenger_provider.dart'; // Importado o novo Provider
import '../../widgets/passenger_card.dart';
import 'passenger_details_page.dart';
import 'add_passenger_page.dart';

class PassengersListPage extends StatefulWidget {
  final String excursionId;

  const PassengersListPage({super.key, required this.excursionId});

  @override
  State<PassengersListPage> createState() => _PassengersListPageState();
}

class _PassengersListPageState extends State<PassengersListPage> {
  String _searchQuery = '';
  PassengerFilter _activeFilter = PassengerFilter.todos;

  @override
  Widget build(BuildContext context) {
    // Usando o PassengerProvider dedicado
    final passengerProvider = context.read<PassengerProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            _buildSearchBar(),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Passenger>>(
                // Consumindo a Stream do PassengerProvider
                stream: passengerProvider.watchPassengers(widget.excursionId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
                  }

                  final allPassengers = snapshot.data ?? [];

                  // --- LÓGICA DE FILTRAGEM REFATORADA COM ENUMS ---
                  final filteredPassengers = allPassengers.where((p) {
                    // 1. Filtro de Texto (Nome)
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());

                    // 2. Filtro de Categoria (Usando BoardingStatus do Model)
                    bool matchesCategory = true;
                    switch (_activeFilter) {
                      case PassengerFilter.pendentes:
                        matchesCategory = p.statusEmbarque == BoardingStatus.aguardando;
                        break;
                      case PassengerFilter.embarcados:
                        matchesCategory = p.statusEmbarque == BoardingStatus.embarcou;
                        break;
                      case PassengerFilter.menores:
                        matchesCategory = p.isMinor;
                        break;
                      case PassengerFilter.todos:
                        matchesCategory = true;
                    }

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (allPassengers.isEmpty) return _buildEmptyState(context);

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) => _PassengerListItem(
                              passenger: filteredPassengers[index],
                              excursionId: widget.excursionId,
                            ),
                            childCount: filteredPassengers.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPassengerPage(excursionId: widget.excursionId)),
        ),
        label: const Text('Novo Passageiro'),
        icon: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  // --- COMPONENTES DE FILTRO ---

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: PassengerFilter.values.map((filter) => _filterChip(filter)).toList(),
      ),
    );
  }

  Widget _filterChip(PassengerFilter filter) {
    final isSelected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter.label), // Usando a label do Enum
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _activeFilter = filter);
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
      ),
    );
  }

  // --- MÉTODOS DE UI ---

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          const Text('Lista de Passageiros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar por nome...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.white10),
          SizedBox(height: 16),
          Text('Nenhum passageiro encontrado.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PassengerListItem extends StatelessWidget {
  final Passenger passenger;
  final String excursionId;
  const _PassengerListItem({required this.passenger, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PassengerCard(
        passenger: passenger,
        excursionId: excursionId,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PassengerDetailsPage(excursionId: excursionId, passenger: passenger),
          ),
        ),
      ),
    );
  }
}