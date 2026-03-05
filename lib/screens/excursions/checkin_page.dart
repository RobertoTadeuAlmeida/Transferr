import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/passenger.dart';
import '../../models/enums.dart';
import '../../providers/passenger_provider.dart';
import '../../config/theme/app_theme.dart';

class CheckInPage extends StatefulWidget {
  final String excursionId;
  final String destinationName;

  const CheckInPage({
    super.key,
    required this.excursionId,
    required this.destinationName,
  });

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String _searchQuery = '';
  BoardingStatus? _selectedFilter; // NULL significa "Todos"
  final TextEditingController _localController = TextEditingController();

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Check-in de Operação'),
            Text(
              widget.destinationName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Passenger>>(
        stream: context.read<PassengerProvider>().watchPassengers(
          widget.excursionId,
        ),
        builder: (context, snapshot) {
          final passengers = snapshot.data ?? [];

          // Cálculos para o filtro
          final countTotal = passengers.length;
          final countEmbarcados = passengers
              .where((p) => p.statusEmbarque == BoardingStatus.embarcou)
              .length;
          final countParada = passengers
              .where((p) => p.statusEmbarque == BoardingStatus.parada)
              .length;
          final countDesembarque = passengers
              .where((p) => p.statusEmbarque == BoardingStatus.desembarcou)
              .length;

          // Aplicação dos Filtros
          final filteredPassengers = passengers.where((p) {
            final matchesSearch =
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.seatNumber.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesStatus =
                _selectedFilter == null || p.statusEmbarque == _selectedFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              _buildOperationHeader(),
              _buildSearchBar(),

              // BARRA DE FILTROS COM CONTADORES
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('Todos', countTotal, null, Colors.white54),
                    _buildFilterChip(
                      'Embarcados',
                      countEmbarcados,
                      BoardingStatus.embarcou,
                      AppTheme.successColor,
                    ),
                    _buildFilterChip(
                      'Em Parada',
                      countParada,
                      BoardingStatus.parada,
                      Colors.orange,
                    ),
                    _buildFilterChip(
                      'Desembarcou',
                      countDesembarque,
                      BoardingStatus.desembarcou,
                      Colors.purpleAccent,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPassengers.isEmpty
                    ? const Center(
                        child: Text("Nenhum passageiro nesta categoria"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPassengers.length,
                        itemBuilder: (context, index) {
                          final p = filteredPassengers[index];
                          return _PassengerCheckInCard(
                            passenger: p,
                            onAction: (status) => _updateStatus(p, status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int count,
    BoardingStatus? status,
    Color color,
  ) {
    final isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
        onSelected: (bool selected) {
          setState(() => _selectedFilter = selected ? status : null);
        },
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? color : Colors.white10),
        ),
      ),
    );
  }

  Widget _buildOperationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _localController,
              decoration: const InputDecoration(
                hintText: 'Localização atual (Ex: Posto Graal)',
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou poltrona...',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          fillColor: AppTheme.cardColor,
        ),
      ),
    );
  }

  void _updateStatus(Passenger passenger, BoardingStatus status) {
    context.read<PassengerProvider>().updateOperationalData(
      context: context,
      passengerId: passenger.id,
      status: status,
      localAtual: _localController.text.isNotEmpty
          ? _localController.text
          : 'Em trânsito',
      excursionId: widget.excursionId,
    );
  }
}

class _PassengerCheckInCard extends StatelessWidget {
  final Passenger passenger;
  final Function(BoardingStatus) onAction;

  const _PassengerCheckInCard({
    required this.passenger,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = passenger.statusEmbarque;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            passenger.seatNumber.isNotEmpty ? passenger.seatNumber : '?',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          passenger.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          status.label,
          style: TextStyle(color: status.color, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: Icons.pause_circle_outline,
              color: Colors.orange,
              isActive: status == BoardingStatus.parada,
              onTap: () => onAction(BoardingStatus.parada),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.check_circle_outline,
              color: AppTheme.successColor,
              isActive: status == BoardingStatus.embarcou,
              onTap: () => onAction(BoardingStatus.embarcou),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.output_rounded,
              color: Colors.purpleAccent,
              isActive: status == BoardingStatus.desembarcou,
              onTap: () => onAction(BoardingStatus.desembarcou),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.white10,
            width: 1,
          ),
        ),
        child: Icon(icon, color: isActive ? color : Colors.white38, size: 24),
      ),
    );
  }
}
