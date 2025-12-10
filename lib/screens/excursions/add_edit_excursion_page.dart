import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../models/excursion.dart';
import '../../providers/client_provider.dart';
import '../../providers/excursion_provider.dart';

class AddEditExcursionPage extends StatefulWidget {
  final Excursion? excursion;
  const AddEditExcursionPage({super.key, this.excursion});

  @override
  State<AddEditExcursionPage> createState() => _AddEditExcursionPageState();
}

class _AddEditExcursionPageState extends State<AddEditExcursionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos do formulário
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _totalSeatsController;
  late final TextEditingController _dateController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController; // BUG 2: CONTROLLER ADICIONADO

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    final excursion = widget.excursion;

    _nameController = TextEditingController(text: excursion?.name ?? '');
    // MELHORIA 1: Formatação correta para evitar '.0' desnecessários
    _priceController = TextEditingController(text: excursion?.price.toStringAsFixed(2) ?? '');
    _totalSeatsController = TextEditingController(text: excursion?.totalSeats.toString() ?? '');
    _locationController = TextEditingController(text: excursion?.location ?? '');
    _descriptionController = TextEditingController(text: excursion?.description ?? ''); // BUG 2: INICIALIZADO

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
    _priceController.dispose();
    _totalSeatsController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose(); // BUG 2: DISPOSE ADICIONADO
    super.dispose();
  }

  Future<void> _saveExcursion() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione uma data para a excursão.'), backgroundColor: Colors.orange));
      }
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ExcursionProvider>();

    try {
      // Cria o objeto Excursion com TODOS os dados do formulário
      final excursionData = Excursion(
        id: widget.excursion?.id,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0,
        totalSeats: int.tryParse(_totalSeatsController.text) ?? 0,
        date: _selectedDate!,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(), // BUG 2: CAMPO ADICIONADO
        isFeatured: _isFeatured, // BUG 1: CAMPO ADICIONADO
        // status e participants usarão os valores padrão do modelo se for uma nova excursão
        status: widget.excursion?.status,
        participants: widget.excursion?.participants ?? [],
      );

      if (widget.excursion == null) {
        await provider.addExcursion(excursionData);
      } else {
        await provider.updateExcursion(excursionData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excursão salva com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar excursão: ${error.toString()}'), backgroundColor: Colors.red));
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Permite datas passadas para edição
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Widget _buildParticipantsSection() {if (widget.excursion == null) {
    return const SizedBox.shrink();
  }

  // 1. Obtenha acesso aos provedores necessários
  final participants = widget.excursion!.participants;
  final clientProvider = context.read<ClientProvider>(); // <-- PASSO CHAVE 1

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Participantes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de adicionar participante a ser implementada!')),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (participants.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Nenhum participante adicionado ainda.',
              style: TextStyle(color: Colors.white70),
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

            // 2. Use o provider para encontrar o nome do cliente pelo ID
            final clientName = clientProvider.getClientById(participant.clientId)?.name ?? 'Cliente não encontrado'; // <-- PASSO CHAVE 2

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white.withOpacity(0.15),
              child: ListTile(
                leading: Icon(
                  participant.status == ParticipantStatus.confirmed ? Icons.check_circle : Icons.person,
                  color: participant.status == ParticipantStatus.confirmed ? Colors.greenAccent : Colors.white70,
                ),
                // 3. Use a variável 'clientName' que acabamos de buscar
                title: Text(clientName, style: const TextStyle(color: Colors.white)), // <-- CORREÇÃO APLICADA
                subtitle: Text(
                  'Pagamento: ${participant.paymentStatus.name}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: Text(
                  'R\$ ${participant.amountPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // TODO: Abrir o dialog para editar este participante específico.
                },
              ),
            );
          },
        ),
    ],
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.excursion == null ? 'Nova Excursão' : 'Editar Excursão'),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveExcursion, tooltip: 'Salvar'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(controller: _nameController, labelText: 'Nome da Excursão', icon: Icons.tour, validator: (value) => value!.isEmpty ? 'Insira um nome' : null),
              _buildTextFormField(controller: _dateController, labelText: 'Data da Excursão', icon: Icons.calendar_today, readOnly: true, onTap: () => _selectDate(context), validator: (value) => value!.isEmpty ? 'Selecione uma data' : null),
              _buildTextFormField(controller: _locationController, labelText: 'Local de Saída', icon: Icons.location_on, validator: (value) => value!.isEmpty ? 'Insira um local' : null),
              // BUG 2: CAMPO DE DESCRIÇÃO ADICIONADO AO FORMULÁRIO
              _buildTextFormField(controller: _descriptionController, labelText: 'Descrição (opcional)', icon: Icons.description, isMultiLine: true),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _priceController,
                      labelText: 'Preço (R\$)',
                      icon: Icons.monetization_on,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      // MELHORIA 2: Validação robusta de número
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Obrigatório';
                        if ((double.tryParse(value.replaceAll(',', '.')) ?? -1) <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _totalSeatsController,
                      labelText: 'Assentos',
                      icon: Icons.event_seat,
                      keyboardType: TextInputType.number,
                      // MELHORIA 2: Validação robusta de número
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Obrigatório';
                        if ((int.tryParse(value) ?? -1) <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Marcar como Destaque', style: TextStyle(color: Colors.white)),
                subtitle: const Text('A excursão aparecerá na tela principal.', style: TextStyle(color: Colors.white70)),
                value: _isFeatured,
                onChanged: (bool value) => setState(() => _isFeatured = value),
                activeColor: const Color(0xFFF97316),
                contentPadding: EdgeInsets.zero,
              ),_buildParticipantsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function()? onTap,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: isMultiLine ? 3 : 1,
        minLines: isMultiLine ? 3 : 1,
      ),
    );
  }
}
