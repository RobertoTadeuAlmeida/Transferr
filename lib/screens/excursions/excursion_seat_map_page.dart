import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/providers/passenger_provider.dart';

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
  String? selectedSeat;

  @override
  Widget build(BuildContext context) {
    final passengerProvider = Provider.of<PassengerProvider>(
      context,
      listen: false,
    );
    final theme = Theme.of(context);

    return StreamBuilder<List<Passenger>>(
      stream: passengerProvider.watchPassengers(widget.excursionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final passengers = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isSelectionMode
                  ? 'Selecionar Assento'
                  : 'Mapa de Assentos',
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildHeaderLegend(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    border: Border.all(color: Colors.white.withAlpha(10)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
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
              if (selectedSeat != null)
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
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
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
          child: const Icon(
            Icons.airline_seat_recline_normal,
            color: Colors.white54,
          ),
        ),
        const Text(
          "INÍCIO DO ÔNIBUS",
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 10,
            color: Colors.white24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSeatGrid(List<Passenger> passengers) {
    int rows = (widget.totalSeats / 4).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        int startSeat = rowIndex * 4;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _buildSeat((startSeat + 1).toString(), passengers),
              const SizedBox(width: 10),
              _buildSeat((startSeat + 2).toString(), passengers),
              const Expanded(
                child: Center(
                  child: Text("|", style: TextStyle(color: Colors.white10)),
                ),
              ),
              _buildSeat((startSeat + 3).toString(), passengers),
              const SizedBox(width: 10),
              _buildSeat((startSeat + 4).toString(), passengers),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeat(String seatStr, List<Passenger> passengers) {
    if (int.parse(seatStr) > widget.totalSeats)
      return const SizedBox(width: 50, height: 50);

    final passengerAtSeat = passengers
        .where((p) => p.seatNumber == seatStr)
        .firstOrNull;

    bool isOccupied = passengerAtSeat != null;
    bool isSelected = selectedSeat == seatStr;

    Color seatColor = isOccupied ? AppTheme.primaryColor : Colors.grey[850]!;
    if (isSelected) seatColor = AppTheme.successColor;

    return GestureDetector(
      onTap: () {
        if (isOccupied && widget.isSelectionMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Este assento já está ocupado"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() => selectedSeat = seatStr);
      },
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
                    color: AppTheme.successColor.withAlpha(100),
                    blurRadius: 8,
                  ),
                ]
              : null,
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

  Widget _buildSelectionPanel(
    List<Passenger> passengers,
    PassengerProvider provider,
    ThemeData theme,
  ) {
    final passengerAtSeat = passengers
        .where((p) => p.seatNumber == selectedSeat)
        .firstOrNull;

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
                  child: Text(
                    selectedSeat!,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
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
                        passengerAtSeat?.name ?? "Assento Selecionado",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Toque no botão para confirmar",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // BOTÃO DE AÇÃO DINÂMICO
                ElevatedButton(
                  onPressed: () {
                    if (widget.isSelectionMode) {
                      // CASO 1: Apenas devolve o número para a AddPassengerPage
                      Navigator.pop(context, selectedSeat);
                    } else {
                      // CASO 2: Se não houver ninguém, abre lista para vincular
                      if (passengerAtSeat == null) {
                        _showPassengerPicker(context, passengers, provider);
                      } else {
                        // Se já houver alguém, oferece desvincular
                        _handleUpdateSeat(provider, passengerAtSeat.id, null);
                        setState(() => selectedSeat = null);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isSelectionMode
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                  ),
                  child: Text(
                    widget.isSelectionMode
                        ? "CONFIRMAR"
                        : (passengerAtSeat == null ? "VINCULAR" : "LIBERAR"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPassengerPicker(
    BuildContext context,
    List<Passenger> passengersInExcursion,
    // Passageiros que já estão na viagem
    PassengerProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      // Permite que o bottom sheet cresça se houver muitos nomes
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.7, // Limita a 70% da tela
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Vincular Passageiro ao Assento",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Passenger>>(
                // BUSCA TODOS OS PASSAGEIROS DO SEU CRM (GLOBAL)
                stream: provider.globalPassengersStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // FILTRO: Remove passageiros que já estão nesta excursão COM assento
                  final available = snapshot.data!.where((pGlobal) {
                    final isInExcursion = passengersInExcursion.any(
                      (pEx) => pEx.id == pGlobal.id,
                    );
                    final hasSeat = passengersInExcursion.any(
                      (pEx) =>
                          pEx.id == pGlobal.id &&
                          pEx.seatNumber != null &&
                          pEx.seatNumber!.isNotEmpty,
                    );

                    return !isInExcursion || !hasSeat;
                  }).toList();

                  if (available.isEmpty) {
                    return const Center(
                      child: Text("Nenhum passageiro disponível no CRM."),
                    );
                  }

                  return ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final p = available[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.person, color: Colors.white70),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          p.document.isEmpty ? "Sem documento" : p.document,
                        ),
                        onTap: () async {
                          final success = await provider.linkExistingPassenger(
                            context: context,
                            passengerId: p.id,
                            excursionId: widget.excursionId,
                            depositValue: 0,
                            totalValue: 0,
                            seatNumber: selectedSeat,
                          );
                          print("passageiro add ao provider $success");

                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Passageiro ${p.name} vinculado à poltrona $selectedSeat com sucesso!",
                                ),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            setState(() {
                              selectedSeat = null;
                            });
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleUpdateSeat(
    PassengerProvider provider,
    String passengerId,
    String? seat,
  ) {
    provider.updateOperationalData(
      context: context,
      passengerId: passengerId,
      seatNumber: seat,
      excursionId: widget.excursionId,
    );
  }
}
