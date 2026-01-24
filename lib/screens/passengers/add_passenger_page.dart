import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/passenger.dart';
import '../../../models/enums.dart';
import '../../../providers/passenger_provider.dart';

class AddPassengerPage extends StatefulWidget {
  final String excursionId;
  final Passenger? passenger;

  const AddPassengerPage({
    super.key,
    required this.excursionId,
    this.passenger,
  });

  @override
  State<AddPassengerPage> createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers Viajante
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _docController;
  late final TextEditingController _seatController;
  late final TextEditingController _depositController; // Controller do Sinal
  DateTime? _selectedBirthDate;

  // Controllers Responsável
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianDocController;
  late final TextEditingController _guardianPhoneController;

  bool _isLoading = false;
  bool _isMinor = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _docMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final p = widget.passenger;
    _nameController = TextEditingController(text: p?.name ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _docController = TextEditingController(text: p?.document ?? '');
    _seatController = TextEditingController(text: p?.seatNumber ?? '');
    _selectedBirthDate = p?.birthDate;

    // Inicialização segura do valor do sinal
    _depositController = TextEditingController(
      text: (p?.depositValue != null && p!.depositValue > 0)
          ? p.depositValue.toStringAsFixed(2)
          : '',
    );

    _guardianNameController = TextEditingController(text: p?.guardian?.name ?? '');
    _guardianDocController = TextEditingController(text: p?.guardian?.document ?? '');
    _guardianPhoneController = TextEditingController(text: p?.guardian?.phone ?? '');

    if (_selectedBirthDate != null) {
      _calculateAge(_selectedBirthDate!);
    }
  }

  void _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    setState(() => _isMinor = age < 18);
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
      _calculateAge(picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a data de nascimento')),
      );
      return;
    }

    // Regra de Negócio: Sinal obrigatório para vincular à excursão
    final double deposit = double.tryParse(_depositController.text.replaceAll(',', '.')) ?? 0.0;

    if (deposit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ O pagamento do sinal é obrigatório para cadastrar na viagem.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final passenger = Passenger(
        id: widget.passenger?.id ?? const Uuid().v4(),
        excursionId: widget.excursionId,
        name: _nameController.text.trim(),
        phone: _phoneController.text,
        document: _docController.text,
        birthDate: _selectedBirthDate!,
        seatNumber: _seatController.text.toUpperCase().trim(),
        depositValue: deposit,
        isMinor: _isMinor,
        statusEmbarque: widget.passenger?.statusEmbarque ?? BoardingStatus.aguardando,
        guardian: _isMinor
            ? Guardian(
          name: _guardianNameController.text.trim(),
          document: _guardianDocController.text,
          phone: _guardianPhoneController.text,
        )
            : null,
      );

      final provider = context.read<PassengerProvider>();
      final success = await provider.savePassenger(
        passenger: passenger,
        excursionId: widget.excursionId,
        depositValue: deposit,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.passenger == null ? '✅ Passageiro adicionado!' : '✅ Dados atualizados!'),
            backgroundColor: Colors.green[800],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.errorMessage ?? "Erro ao salvar"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro inesperado: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passenger == null ? 'Adicionar Passageiro' : 'Editar Passageiro'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(Icons.person, 'Dados do Passageiro'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome Completo'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _docController,
                    inputFormatters: [_docMask],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Documento (RG/CPF)'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _seatController,
                    decoration: const InputDecoration(labelText: 'Poltrona', hintText: '12A'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              inputFormatters: [_phoneMask],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            const SizedBox(height: 16),
            _buildBirthDatePicker(),

            const SizedBox(height: 32),
            _buildSectionHeader(Icons.payments_outlined, 'Financeiro', color: Colors.green),
            TextFormField(
              controller: _depositController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Valor do Sinal (R\$)',
                prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                helperText: 'Obrigatório para confirmar a vaga na viagem.',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                final val = double.tryParse(v.replaceAll(',', '.'));
                if (val == null || val <= 0) return 'Valor inválido';
                return null;
              },
            ),

            if (_isMinor) ...[
              const SizedBox(height: 32),
              _buildSectionHeader(Icons.family_restroom, 'Dados do Responsável', color: Colors.orange),
              TextFormField(
                controller: _guardianNameController,
                decoration: const InputDecoration(labelText: 'Nome do Responsável'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => _isMinor && v!.isEmpty ? 'Informe o nome do responsável' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _guardianDocController,
                      decoration: const InputDecoration(labelText: 'Doc. Responsável'),
                      validator: (v) => _isMinor && v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _guardianPhoneController,
                      inputFormatters: [_phoneMask],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Tel. Responsável'),
                      validator: (v) => _isMinor && v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.passenger == null ? 'CONFIRMAR E ADICIONAR' : 'SALVAR ALTERAÇÕES',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blue),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildBirthDatePicker() {
    return InkWell(
      onTap: () => _selectBirthDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedBirthDate == null
                        ? 'Data de Nascimento'
                        : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)}',
                    style: TextStyle(color: _selectedBirthDate == null ? Colors.grey : Colors.white),
                  ),
                  if (_selectedBirthDate != null)
                    Text(
                      _isMinor ? 'Passageiro Menor de Idade' : 'Passageiro Maior de Idade',
                      style: TextStyle(color: _isMinor ? Colors.orange : Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month, size: 20, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}