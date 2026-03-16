import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/passenger.dart';
import '../../models/enums.dart';
import '../../providers/passenger_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../config/theme/app_theme.dart';

class CheckInPage extends StatefulWidget {
  final String excursionId;
  final String destinationName;
  final bool isStarting;
  final bool isFinishing; // Novo modo para fechamento da viagem

  const CheckInPage({
    super.key,
    required this.excursionId,
    required this.destinationName,
    this.isStarting = false,
    this.isFinishing = false,
  });

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String _searchQuery = '';
  BoardingStatus? _selectedFilter;
  final TextEditingController _localController = TextEditingController();

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passengerProvider = context.read<PassengerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(
              widget.destinationName,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Passenger>>(
        stream: passengerProvider.watchPassengers(widget.excursionId),
        builder: (context, snapshot) {
          final passengers = snapshot.data ?? [];

          // REGRA DE OURO: Validação de "Ninguém para trás"
          final int total = passengers.length;
          final int processados = _countProcessed(passengers);
          final bool prontoParaAcao = total > 0 && processados == total;

          final filteredPassengers = _filterPassengers(passengers);

          return Column(
            children: [
              if (!widget.isStarting && !widget.isFinishing) _buildOperationHeader(),
              _buildSearchBar(),
              _buildFilterBar(passengers),

              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPassengers.isEmpty
                    ? const Center(child: Text("Nenhum passageiro encontrado"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPassengers.length,
                        itemBuilder: (context, index) {
                          final p = filteredPassengers[index];
                          return _PassengerCheckInCard(
                            passenger: p,
                            mode: _getCurrentMode(),
                            onAction: (status) => _updateStatus(p, status),
                          );
                        },
                      ),
              ),
              
              if (widget.isStarting || widget.isFinishing)
                _buildActionFooter(context, prontoParaAcao, processados, total),
            ],
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    if (widget.isStarting) return 'Validar Embarque Inicial';
    if (widget.isFinishing) return 'Validar Desembarque Final';
    return 'Check-in de Operação';
  }

  _CheckInMode _getCurrentMode() {
    if (widget.isStarting) return _CheckInMode.starting;
    if (widget.isFinishing) return _CheckInMode.finishing;
    return _CheckInMode.normal;
  }

  int _countProcessed(List<Passenger> passengers) {
    if (widget.isStarting) {
      // No início: Todos devem ter status diferente de AGUARDANDO
      return passengers.where((p) => p.statusEmbarque != BoardingStatus.aguardando).length;
    }
    if (widget.isFinishing) {
      // No final: Todos que embarcaram devem ter DESEMBARCOU. Quem não embarcou fica como NAO_EMBARCOU.
      return passengers.where((p) => 
        p.statusEmbarque == BoardingStatus.desembarcou || 
        p.statusEmbarque == BoardingStatus.naoEmbarcou
      ).length;
    }
    return 0;
  }

  List<Passenger> _filterPassengers(List<Passenger> passengers) {
    return passengers.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           p.seatNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedFilter == null || p.statusEmbarque == _selectedFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildFilterBar(List<Passenger> passengers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos', passengers.length, null, Colors.white54),
          _buildFilterChip('Embarcados', passengers.where((p) => p.statusEmbarque == BoardingStatus.embarcou).length, BoardingStatus.embarcou, AppTheme.successColor),
          if (!widget.isStarting && !widget.isFinishing)
            _buildFilterChip('Em Parada', passengers.where((p) => p.statusEmbarque == BoardingStatus.parada).length, BoardingStatus.parada, Colors.orange),
          _buildFilterChip('No Destino', passengers.where((p) => p.statusEmbarque == BoardingStatus.desembarcou).length, BoardingStatus.desembarcou, Colors.purpleAccent),
          _buildFilterChip('Faltou', passengers.where((p) => p.statusEmbarque == BoardingStatus.naoEmbarcou).length, BoardingStatus.naoEmbarcou, AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildActionFooter(BuildContext context, bool enabled, int current, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.isStarting ? "Conferência Inicial:" : "Conferência de Desembarque:", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("$current / $total validados", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enabled ? () => _handleMainAction(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isFinishing ? Colors.purple : AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.isStarting ? "TUDO PRONTO! INICIAR VIAGEM" : "ENCERRAR EXCURSÃO E ATUALIZAR CRM"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMainAction(BuildContext context) async {
    final provider = context.read<ExcursionProvider>();
    try {
      if (widget.isStarting) {
        await provider.startExcursion(widget.excursionId);
      } else {
        await provider.finalizeExcursion(widget.excursionId);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isStarting ? "Viagem Iniciada!" : "Viagem Concluída e CRM atualizado!"),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, int count, BoardingStatus? status, Color color) {
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
                color: isSelected ? Colors.white24 : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color),
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
          const Icon(Icons.coffee_outlined, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _localController,
              decoration: const InputDecoration(
                hintText: 'Ponto de Parada (Ex: Graal, Restaurante...)',
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
    String local = 'Em trânsito';
    if (widget.isStarting) local = 'Local de Partida';
    if (widget.isFinishing) local = 'Destino Final / Retorno';
    if (_localController.text.isNotEmpty) local = _localController.text;

    context.read<PassengerProvider>().updateOperationalData(
      context: context,
      passengerId: passenger.id,
      status: status,
      localAtual: local,
      excursionId: widget.excursionId,
    );
  }
}

enum _CheckInMode { starting, finishing, normal }

class _PassengerCheckInCard extends StatelessWidget {
  final Passenger passenger;
  final _CheckInMode mode;
  final Function(BoardingStatus) onAction;

  const _PassengerCheckInCard({
    required this.passenger,
    required this.mode,
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
            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(passenger.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status.label, style: TextStyle(color: status.color, fontSize: 12)),
        trailing: _buildActions(status),
      ),
    );
  }

  Widget _buildActions(BoardingStatus currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mode == _CheckInMode.starting) ...[
          _ActionButton(
            icon: Icons.check_circle_outline,
            color: AppTheme.successColor,
            isActive: currentStatus == BoardingStatus.embarcou,
            onTap: () => onAction(BoardingStatus.embarcou),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.cancel_outlined,
            color: AppTheme.errorColor,
            isActive: currentStatus == BoardingStatus.naoEmbarcou,
            onTap: () => onAction(BoardingStatus.naoEmbarcou),
          ),
        ] else if (mode == _CheckInMode.finishing) ...[
          _ActionButton(
            icon: Icons.location_on_outlined,
            color: Colors.purpleAccent,
            isActive: currentStatus == BoardingStatus.desembarcou,
            onTap: () => onAction(BoardingStatus.desembarcou),
          ),
          // Se o passageiro nunca embarcou, ele já deve estar como NAO_EMBARCOU
          if (currentStatus == BoardingStatus.aguardando) ...[
             const SizedBox(width: 8),
             _ActionButton(
              icon: Icons.cancel_outlined,
              color: AppTheme.errorColor,
              isActive: currentStatus == BoardingStatus.naoEmbarcou,
              onTap: () => onAction(BoardingStatus.naoEmbarcou),
            ),
          ]
        ] else ...[
          _ActionButton(
            icon: Icons.check_circle_outline,
            color: AppTheme.successColor,
            isActive: currentStatus == BoardingStatus.embarcou,
            onTap: () => onAction(BoardingStatus.embarcou),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.coffee_outlined,
            color: Colors.orange,
            isActive: currentStatus == BoardingStatus.parada,
            onTap: () => onAction(BoardingStatus.parada),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.location_on_outlined,
            color: Colors.purpleAccent,
            isActive: currentStatus == BoardingStatus.desembarcou,
            onTap: () => onAction(BoardingStatus.desembarcou),
          ),
        ]
      ],
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
          border: Border.all(color: isActive ? color : Colors.white10, width: 1),
        ),
        child: Icon(icon, color: isActive ? color : Colors.white38, size: 24),
      ),
    );
  }
}
