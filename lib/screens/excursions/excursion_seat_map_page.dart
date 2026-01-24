import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/providers/passenger_provider.dart';

class ExcursionSeatMapPage extends StatefulWidget {
  final String excursionId;
  final int totalSeats;

  const ExcursionSeatMapPage({
    super.key,
    required this.excursionId,
    this.totalSeats = 44,
  });

  @override
  State<ExcursionSeatMapPage> createState() => _ExcursionSeatMapPageState();
}

class _ExcursionSeatMapPageState extends State<ExcursionSeatMapPage> {
  int? selectedSeat;

  @override
  Widget build(BuildContext context) {
    final passengerProvider = Provider.of<PassengerProvider>(context, listen: false);
    final theme = Theme.of(context);

    return StreamBuilder<List<Passenger>>(
      stream: passengerProvider.watchPassengers(widget.excursionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final passengers = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mapa de Assentos'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildHeaderLegend(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border.all(color: Colors.white.withAlpha(10)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildDriverSection(),
                        const SizedBox(height: 24),
                        _buildSeatGrid(passengers),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSelectionPanel(passengers, passengerProvider, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statusIndicator("Livre", Colors.grey[800]!),
          _statusIndicator("Ocupado", AppTheme.primaryColor),
          _statusIndicator("Selecionado", AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _statusIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDriverSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.airline_seat_recline_normal, color: Colors.white54),
        ),
        const Text("INÍCIO DO ÔNIBUS",
            style: TextStyle(letterSpacing: 2, fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSeatGrid(List<Passenger> passengers) {
    int rows = (widget.totalSeats / 4).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildSeat(rowIndex * 4 + 1, passengers),
              const SizedBox(width: 10),
              _buildSeat(rowIndex * 4 + 2, passengers),
              const Expanded(child: Center(child: Text("|", style: TextStyle(color: Colors.white10)))),
              _buildSeat(rowIndex * 4 + 3, passengers),
              const SizedBox(width: 10),
              _buildSeat(rowIndex * 4 + 4, passengers),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeat(int seatNumber, List<Passenger> passengers) {
    if (seatNumber > widget.totalSeats) return const SizedBox(width: 50, height: 50);

    final String seatStr = seatNumber.toString();
    final passengerAtSeat = passengers.where((p) => p.seatNumber == seatStr).firstOrNull;

    bool isOccupied = passengerAtSeat != null;
    bool isSelected = selectedSeat == seatNumber;

    Color seatColor = isOccupied ? AppTheme.primaryColor : Colors.grey[850]!;
    if (isSelected) seatColor = AppTheme.successColor;

    return GestureDetector(
      onTap: () => setState(() => selectedSeat = seatNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.successColor.withAlpha(100), blurRadius: 8)] : null,
        ),
        child: Center(
          child: Text(
            seatStr,
            style: TextStyle(
              color: isOccupied || isSelected ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionPanel(List<Passenger> passengers, PassengerProvider provider, ThemeData theme) {
    if (selectedSeat == null) return const SizedBox.shrink();

    final String seatStr = selectedSeat.toString();
    final passengerAtSeat = passengers.where((p) => p.seatNumber == seatStr).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withAlpha(30),
                  child: Text(seatStr, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerAtSeat?.name ?? "Assento Disponível",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (passengerAtSeat != null)
                        Row(
                          children: [
                            Text(
                              passengerAtSeat.statusEmbarque.label.toUpperCase(),
                              style: TextStyle(color: passengerAtSeat.statusEmbarque.color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text("•", style: TextStyle(color: Colors.white24)),
                            const SizedBox(width: 8),
                            Text(
                              "PAGO: R\$ ${passengerAtSeat.depositValue.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        )
                      else
                        const Text("Nenhum passageiro vinculado", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                if (passengerAtSeat == null)
                  ElevatedButton(
                    onPressed: () => _showPassengerPicker(context, passengers, provider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text("VINCULAR"),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.link_off, color: AppTheme.errorColor),
                    onPressed: () => _handleUpdateSeat(provider, passengerAtSeat.id!, null),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPassengerPicker(BuildContext context, List<Passenger> allPassengers, PassengerProvider provider) {
    final unseated = allPassengers.where((p) => p.seatNumber == null || p.seatNumber!.isEmpty).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Selecione o Passageiro", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (unseated.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("Todos os passageiros já possuem assento.", style: TextStyle(color: Colors.white38)),
            )
          else
            Flexible(
              child: ListView.builder(
                itemCount: unseated.length,
                itemBuilder: (context, index) {
                  final p = unseated[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                    title: Text(p.name),
                    subtitle: Text("Doc: ${p.document}"),
                    onTap: () {
                      _handleUpdateSeat(provider, p.id!, selectedSeat.toString());
                      Navigator.pop(context);
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

  void _handleUpdateSeat(PassengerProvider provider, String passengerId, String? seat) {
    provider.updatePassengerSeat(passengerId, seat);
  }
}