import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/excursion.dart';
import '../../models/enums.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditExcursionPage extends StatefulWidget {
  final Excursion? excursion;

  const AddEditExcursionPage({super.key, this.excursion});

  @override
  State<AddEditExcursionPage> createState() => _AddEditExcursionPageState();
}

class _AddEditExcursionPageState extends State<AddEditExcursionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _destIdController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  // O Slug não tem mais controller visual, apenas uma variável
  String _currentSlug = '';

  late DateTime _startDate;
  late DateTime _returnDate;
  late ExcursionStatus _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.excursion;

    _nameController = TextEditingController(text: e?.name ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _destIdController = TextEditingController(text: e?.idMainDestination ?? '');
    _priceController = TextEditingController(
      text: e != null ? e.basePrice.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _seatsController = TextEditingController(text: e?.totalSeats.toString() ?? '44');

    _currentSlug = e?.slug ?? '';
    _startDate = e?.startDate ?? DateTime.now().add(const Duration(days: 7));
    _returnDate = e?.returnDate ?? DateTime.now().add(const Duration(days: 9));

    // Status inicial: Se for novo, padrão Programada. Se editar, mantém o anterior.
    _selectedStatus = e?.status ?? ExcursionStatus.programada;
  }

  void _updateSlug(String name) {
    setState(() {
      _currentSlug = name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-');
    });
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _returnDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _returnDate),
      );
      if (time != null) {
        setState(() {
          final newDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) {
            _startDate = newDate;
          } else {
            _returnDate = newDate;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final excursionProvider = context.read<ExcursionProvider>();

    // Tratamento do preço (converte vírgula da máscara para ponto do double)
    final priceString = _priceController.text.replaceAll(',', '.');
    final price = double.tryParse(priceString) ?? 0.0;

    final excursion = Excursion(
      id: widget.excursion?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      idMainDestination: _destIdController.text.trim(),
      startDate: _startDate,
      returnDate: _returnDate,
      basePrice: price,
      totalSeats: int.tryParse(_seatsController.text) ?? 0,
      reservedSeats: widget.excursion?.reservedSeats ?? 0,
      slug: _currentSlug,
      status: _selectedStatus,
      idResponsible: widget.excursion?.idResponsible ?? authProvider.currentUser?.id ?? '',
    );

    try {
      if (widget.excursion == null) {
        await excursionProvider.addExcursion(excursion);
      } else {
        await excursionProvider.updateExcursion(excursion);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.excursion == null ? 'Nova Excursão' : 'Editar Excursão'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Excursão',
                prefixIcon: Icon(Icons.directions_bus),
                border: OutlineInputBorder(),
              ),
              onChanged: _updateSlug,
              validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destIdController,
              decoration: const InputDecoration(
                labelText: 'Cidade de Destino',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Informe o destino' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Descrição / Roteiro',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _seatsController,
                    decoration: const InputDecoration(
                      labelText: 'Vagas',
                      prefixIcon: Icon(Icons.event_seat),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Cronograma", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDateTile('Data/Hora Partida', _startDate, () => _selectDateTime(context, true)),
            _buildDateTile('Data/Hora Retorno', _returnDate, () => _selectDateTime(context, false)),
            const Divider(height: 40),

            // Switch de Status (Programada vs Em Andamento)
            SwitchListTile(
              title: Text(_selectedStatus == ExcursionStatus.emAndamento
                  ? 'Status: EM ANDAMENTO'
                  : 'Status: PROGRAMADA'),
              subtitle: const Text('Arraste para mudar o status da excursão'),
              secondary: Icon(
                _selectedStatus == ExcursionStatus.emAndamento ? Icons.play_circle : Icons.pause_circle,
                color: _selectedStatus == ExcursionStatus.emAndamento ? Colors.green : Colors.orange,
              ),
              value: _selectedStatus == ExcursionStatus.emAndamento,
              onChanged: (bool value) {
                setState(() {
                  _selectedStatus = value
                      ? ExcursionStatus.emAndamento
                      : ExcursionStatus.programada;
                });
              },
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                widget.excursion == null ? 'CRIAR EXCURSÃO' : 'ATUALIZAR DADOS',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        DateFormat('dd/MM/yyyy - HH:mm').format(date),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.edit, size: 18),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _destIdController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }
}