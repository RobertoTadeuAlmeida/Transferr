import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';

class ExcursionSeatMapPage extends StatefulWidget {
  final String excursionId;
  final int totalSeats;
  final String? initialSelectedSeat;
  final bool isSelectionMode;

  const ExcursionSeatMapPage({
    super.key,
    required this.excursionId,
    this.totalSeats = 44,
    this.initialSelectedSeat,
    this.isSelectionMode = false,
  });

  @override
  State<ExcursionSeatMapPage> createState() => _ExcursionSeatMapPageState();
}

class _ExcursionSeatMapPageState extends State<ExcursionSeatMapPage> {
  String? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _selectedSeat = widget.initialSelectedSeat;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passengerProvider = context.read<PassengerProvider>();

    return StreamBuilder<List<Passenger>>(
      stream: passengerProvider.watchPassengers(widget.excursionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final passengers = snapshot.data ?? [];
        final seatMap = {for (var p in passengers) p.seatNumber: p};

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isSelectionMode ? 'Selecionar Assento' : 'Mapa de Assentos',
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildHeaderLegend(),
              Expanded(
                child: _buildBusFrame(
                  theme: theme,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildDriverSection(theme),
                      const SizedBox(height: 24),
                      _buildSeatGrid(seatMap, theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              if (_selectedSeat != null)
                _SelectionPanel(
                  selectedSeat: _selectedSeat!,
                  isSelectionMode: widget.isSelectionMode,
                  excursionId: widget.excursionId,
                  passengers: passengers,
                  passengerAtSeat: seatMap[_selectedSeat],
                  onActionComplete: () => setState(() => _selectedSeat = null),
                  onConfirmed: (seat) => Navigator.pop(context, seat),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusFrame({required ThemeData theme, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: child,
      ),
    );
  }

  Widget _buildHeaderLegend() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatusIndicator(label: "Livre", color: Color(0xFF2C2C2C)),
          _StatusIndicator(label: "Ocupado", color: AppTheme.primaryColor),
          _StatusIndicator(label: "Selecionado", color: AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildDriverSection(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Icon(Icons.settings_input_component, color: Colors.white24, size: 20),
              SizedBox(width: 8),
              Icon(Icons.airline_seat_recline_normal, color: Colors.white54, size: 24),
            ],
          ),
        ),
        Text(
          "FRENTE",
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 4,
            color: Colors.white12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sensor_door_outlined, color: Colors.white12, size: 20),
        ),
      ],
    );
  }

  Widget _buildSeatGrid(Map<String, Passenger> seatMap, ThemeData theme) {
    final int rows = (widget.totalSeats / 4).ceil();
    return Column(
      children: List.generate(rows, (rowIndex) {
        final int startSeat = rowIndex * 4;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 1; i <= 4; i++) ...[
                _SeatWidget(
                  seatNumber: (startSeat + i).toString(),
                  totalSeats: widget.totalSeats,
                  isSelected: _selectedSeat == (startSeat + i).toString(),
                  passenger: seatMap[(startSeat + i).toString()],
                  onTap: _handleSeatTap,
                ),
                if (i == 2)
                  const Expanded(
                    child: Center(
                      child: Text("|", style: TextStyle(color: Colors.white10)),
                    ),
                  ),
                if (i != 2 && i != 4) const SizedBox(width: 8),
              ]
            ],
          ),
        );
      }),
    );
  }

  void _handleSeatTap(String seatNumber, bool isOccupied) {
    if (isOccupied && widget.isSelectionMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este assento já está ocupado"),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _selectedSeat = seatNumber);
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final String seatNumber;
  final int totalSeats;
  final bool isSelected;
  final Passenger? passenger;
  final Function(String, bool) onTap;

  const _SeatWidget({
    required this.seatNumber,
    required this.totalSeats,
    required this.isSelected,
    this.passenger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (int.parse(seatNumber) > totalSeats) {
      return const SizedBox(width: 50, height: 50);
    }

    final bool isOccupied = passenger != null;
    Color seatColor = isOccupied ? AppTheme.primaryColor : const Color(0xFF2C2C2C);
    if (isSelected) seatColor = AppTheme.successColor;

    return GestureDetector(
      onTap: () => onTap(seatNumber, isOccupied),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppTheme.successColor.withValues(alpha: 0.3),
              blurRadius: 8,
            )
          ]
              : null,
          border: Border.all(
            color: isSelected ? Colors.white24 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            seatNumber,
            style: TextStyle(
              color: isOccupied || isSelected ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  final String selectedSeat;
  final bool isSelectionMode;
  final String excursionId;
  final List<Passenger> passengers;
  final Passenger? passengerAtSeat;
  final VoidCallback onActionComplete;
  final Function(String) onConfirmed;

  const _SelectionPanel({
    required this.selectedSeat,
    required this.isSelectionMode,
    required this.excursionId,
    required this.passengers,
    this.passengerAtSeat,
    required this.onActionComplete,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: const Border(top: BorderSide(color: Colors.white10)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    selectedSeat,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerAtSeat?.name ?? "Assento Livre",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isSelectionMode
                            ? "Confirme para selecionar este assento"
                            : (passengerAtSeat == null
                            ? "Disponível para vínculo"
                            : "Ocupado"),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    if (isSelectionMode) {
      return ElevatedButton(
        onPressed: () => onConfirmed(selectedSeat),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
        child: const Text("CONFIRMAR"),
      );
    }

    if (passengerAtSeat == null) {
      return ElevatedButton(
        onPressed: () => _showPassengerPicker(context),
        child: const Text("VINCULAR"),
      );
    }

    return ElevatedButton(
      onPressed: () => _confirmRelease(context, theme),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.8),
      ),
      child: const Text("LIBERAR"),
    );
  }

  void _confirmRelease(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liberar Assento?"),
        content: Text("Deseja remover ${passengerAtSeat!.name} da poltrona $selectedSeat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () {
              Navigator.pop(context);
              _handleReleaseSeat(context);
            },
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  void _handleReleaseSeat(BuildContext context) {
    context.read<PassengerProvider>().updateOperationalData(
      context: context,
      passengerId: passengerAtSeat!.id,
      seatNumber: "",
      excursionId: excursionId,
    );
    onActionComplete();
  }

  void _showPassengerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PassengerPickerSheet(
        excursionId: excursionId,
        selectedSeat: selectedSeat,
        passengersInExcursion: passengers,
        onLinked: onActionComplete,
      ),
    );
  }
}

class _PassengerPickerSheet extends StatefulWidget {
  final String excursionId;
  final String selectedSeat;
  final List<Passenger> passengersInExcursion;
  final VoidCallback onLinked;

  const _PassengerPickerSheet({
    required this.excursionId,
    required this.selectedSeat,
    required this.passengersInExcursion,
    required this.onLinked,
  });

  @override
  State<_PassengerPickerSheet> createState() => _PassengerPickerSheetState();
}

class _PassengerPickerSheetState extends State<_PassengerPickerSheet> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PassengerProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Vincular Passageiro",
              style: theme.textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: "Buscar por nome ou documento...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Passenger>>(
              stream: provider.globalPassengersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.where((pGlobal) {
                  final exP = widget.passengersInExcursion
                      .where((pEx) => pEx.id == pGlobal.id)
                      .firstOrNull;
                  
                  final matchesSearch = pGlobal.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      pGlobal.document.contains(_searchQuery);
                  
                  return (exP == null || exP.seatNumber.isEmpty) && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.white12),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? "Nenhum passageiro disponível para vínculo." 
                                : "Nenhum passageiro encontrado para '$_searchQuery'",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(Icons.person, color: Colors.white54),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        p.document.isEmpty ? "Sem documento" : p.document,
                      ),
                      onTap: () => _handleLink(context, provider, p),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleLink(
      BuildContext context,
      PassengerProvider provider,
      Passenger p,
      ) async {
    final excursion = context
        .read<ExcursionProvider>()
        .excursions
        .firstWhere((e) => e.id == widget.excursionId);

    final success = await provider.linkExistingPassenger(
      context: context,
      passengerId: p.id,
      excursionId: widget.excursionId,
      depositValue: 0,
      totalValue: excursion.basePrice,
      seatNumber: widget.selectedSeat,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${p.name} vinculado com sucesso!"),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
      widget.onLinked();
    }
  }
}
