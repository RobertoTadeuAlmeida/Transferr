import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import 'package:transferr/utils/double_extensions.dart';
import '../../models/enums.dart';
import '../../models/excursion.dart';
import '../../providers/excursion_provider.dart';
import 'add_passenger_page.dart';
import 'participant_detail_page.dart';

class AddEditExcursionPage extends StatefulWidget {
  final Excursion? excursion;
  const AddEditExcursionPage({super.key, this.excursion});

  @override
  State<AddEditExcursionPage> createState() => _AddEditExcursionPageState();
}

class _AddEditExcursionPageState extends State<AddEditExcursionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _pricePerPersonController;
  late final TextEditingController _totalSeatsController;
  late final TextEditingController _dateController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isFeatured = false;

  // Lógica de initState, dispose, _saveExcursion, e _selectDate permanece a mesma.
  // Apenas as SnackBars foram atualizadas para usarem as cores do tema.
  @override
  void initState() {
    super.initState();
    final excursion = widget.excursion;
    _nameController = TextEditingController(text: excursion?.name ?? '');
    _pricePerPersonController = TextEditingController(
      text: excursion?.pricePerPerson.toString().replaceAll('.', ',') ?? '',
    );
    _totalSeatsController = TextEditingController(text: excursion?.totalSeats.toString() ?? '');
    _locationController = TextEditingController(text: excursion?.location ?? '');
    _descriptionController = TextEditingController(text: excursion?.description ?? '');

    if (excursion != null) {
      _selectedDate = excursion.date;
      _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(excursion.date));
      _isFeatured = excursion.isFeatured;
    } else {
      _dateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pricePerPersonController.dispose();
    _totalSeatsController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExcursion() async {
    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Por favor, selecione uma data para a excursão.'),
            backgroundColor: AppTheme.warningColor.withOpacity(0.8),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ExcursionProvider>();

    try {
      final excursionData = Excursion(
        id: widget.excursion?.id,
        name: _nameController.text.trim(),
        price: double.tryParse(_pricePerPersonController.text.replaceAll(',', '.')) ?? 0.0,
        pricePerPerson: double.tryParse(_pricePerPersonController.text.replaceAll(',', '.')) ?? 0.0,
        totalSeats: int.tryParse(_totalSeatsController.text) ?? 0,
        date: _selectedDate!,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        isFeatured: _isFeatured,
        status: widget.excursion?.status ?? ExcursionStatus.agendada,
        participants: widget.excursion?.participants ?? [],
      );

      if (widget.excursion == null) {
        await provider.addExcursion(excursionData);
      } else {
        await provider.updateExcursion(excursionData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Excursão salva com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${error.toString()}'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.excursion == null ? 'Nova Excursão' : 'Editar Excursão'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: CircularProgressIndicator()))
          else
            IconButton(icon: const Icon(Icons.save_alt_rounded), onPressed: _saveExcursion, tooltip: 'Salvar'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Excursão', prefixIcon: Icon(Icons.tour)),
                validator: (value) => (value?.isEmpty ?? true) ? 'Insira um nome' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Data da Excursão', prefixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => (value?.isEmpty ?? true) ? 'Selecione uma data' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Local de Saída', prefixIcon: Icon(Icons.location_on)),
                validator: (value) => (value?.isEmpty ?? true) ? 'Insira um local' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerPersonController,
                      decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixIcon: Icon(Icons.monetization_on)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.isEmpty || (double.tryParse(v.replaceAll(',', '.')) ?? -1) < 0) ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalSeatsController,
                      decoration: const InputDecoration(labelText: 'Assentos', prefixIcon: Icon(Icons.event_seat)),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty || (int.tryParse(v) ?? 0) <= 0) ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)', prefixIcon: Icon(Icons.description)),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text('Marcar como Destaque', style: textTheme.bodyLarge),
                subtitle: Text('A excursão aparecerá na tela principal.', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                value: _isFeatured,
                onChanged: (bool value) => setState(() => _isFeatured = value),
                contentPadding: EdgeInsets.zero,
                // O estilo agora vem do SwitchThemeData
              ),
              if (widget.excursion != null) _buildParticipantsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(BuildContext context) {
    final participants = widget.excursion!.participants;
    final textTheme = Theme.of(context).textTheme;

    IconData getParticipantIcon(PaymentStatus status) {
      switch (status) {
        case PaymentStatus.paid:
          return Icons.check_circle_rounded;
        case PaymentStatus.free:
          return Icons.celebration_rounded;
        default:
          return Icons.person_outline_rounded;
      }
    }

    Color getParticipantColor(PaymentStatus status) {
      switch (status) {
        case PaymentStatus.paid:
          return AppTheme.successColor;
        case PaymentStatus.free:
          return AppTheme.infoColor;
        default:
          return AppTheme.warningColor;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Participantes (${participants.length})', style: textTheme.headlineSmall),
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Adicionar'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => AddPassengerPage(excursionId: widget.excursion!.id!)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (participants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Nenhum participante adicionado ainda.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              final statusColor = getParticipantColor(participant.paymentStatus);
              return Card(
                child: ListTile(
                  leading: Icon(getParticipantIcon(participant.paymentStatus), color: statusColor),
                  title: Text(participant.name, style: textTheme.bodyLarge),
                  subtitle: Text(
                    'Pagamento: ${participant.paymentStatus.name}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  trailing: Text(
                    participant.amountPaid.toCurrency(),
                    style: textTheme.bodyMedium?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ParticipantDetailPage(
                        excursionId: widget.excursion!.id!,
                        initialParticipant: participant,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
