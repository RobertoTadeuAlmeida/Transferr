import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';
import '../../models/passenger.dart';
import '../../models/enums.dart';
import '../../providers/passenger_provider.dart';
import '../../config/theme/app_theme.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class AddPassengerPage extends StatefulWidget {
  final String excursionId;
  final double? excursionPrice; 
  final Passenger? passenger;

  const AddPassengerPage({
    super.key,
    required this.excursionId,
    this.excursionPrice,
    this.passenger,
  });

  @override
  State<AddPassengerPage> createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _docController;
  late final TextEditingController _seatController;
  late final TextEditingController _depositController;
  DateTime? _selectedBirthDate;

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

  final CurrencyTextInputFormatter _currencyFormatter =
      CurrencyTextInputFormatter.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
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

    String initialDepositText = '';
    if (p?.depositValue != null && p!.depositValue > 0) {
      initialDepositText = _currencyFormatter.formatDouble(p.depositValue);
    }
    _depositController = TextEditingController(text: initialDepositText);

    _guardianNameController = TextEditingController(
      text: p?.guardian?.name ?? '',
    );
    _guardianDocController = TextEditingController(
      text: p?.guardian?.document ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: p?.guardian?.phone ?? '',
    );

    if (_selectedBirthDate != null) _calculateAge(_selectedBirthDate!);
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

  /// Corrige o valor automaticamente se ultrapassar o preço da excursão
  void _onDepositChanged(String value) {
    if (widget.excursionPrice == null) return;

    final double currentVal = _currencyFormatter.getUnformattedValue().toDouble();
    
    if (currentVal > widget.excursionPrice!) {
      // Se maior, trava no valor máximo
      final String formattedMax = _currencyFormatter.formatDouble(widget.excursionPrice!);
      
      // Atualiza o controller e posiciona o cursor no final
      _depositController.value = TextEditingValue(
        text: formattedMax,
        selection: TextSelection.collapsed(offset: formattedMax.length),
      );

      // Feedback visual rápido
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Valor ajustado para o máximo da excursão: $formattedMax'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    // Validação mínima: apenas campos vazios obrigatórios
    if (!_formKey.currentState!.validate()) return;

    final double deposit = _currencyFormatter.getUnformattedValue().toDouble();

    setState(() => _isLoading = true);

    try {
      final passenger = Passenger(
        id: widget.passenger?.id ?? const Uuid().v4(),
        excursionId: widget.excursionId,
        name: _nameController.text.trim(),
        phone: _phoneController.text,
        document: _docController.text,
        birthDate: _selectedBirthDate ?? DateTime.now(),
        seatNumber: _seatController.text.toUpperCase().trim(),
        depositValue: deposit,
        isMinor: _isMinor,
        statusEmbarque:
            widget.passenger?.statusEmbarque ?? BoardingStatus.aguardando,
        guardian: _isMinor
            ? Guardian(
                name: _guardianNameController.text.trim(),
                document: _guardianDocController.text,
                phone: _guardianPhoneController.text,
              )
            : null,
      );

      final success = await context.read<PassengerProvider>().savePassenger(
        context: context,
        passenger: passenger,
        excursionId: widget.excursionId,
        depositValue: deposit,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExcursionFlow = widget.excursionId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.passenger == null ? 'Novo Cadastro' : 'Editar Dados',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader(context, Icons.person_outline, 'Identificação'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
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
                          decoration: const InputDecoration(labelText: 'CPF/RG'),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBirthDateField(theme)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    inputFormatters: [_phoneMask],
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp/Celular',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),

                  if (isExcursionFlow) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      context,
                      Icons.directions_bus_outlined,
                      'Vínculo com a Viagem',
                      color: AppTheme.primaryColor,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _seatController,
                            readOnly: true,
                            onTap: () async {
                              final selectedSeat = await Navigator.pushNamed(
                                context,
                                '/map-seats',
                                arguments: {
                                  'excursionId': widget.excursionId,
                                  'currentSeat': _seatController.text,
                                  'isSelectionMode': true,
                                },
                              );
                              if (selectedSeat != null && selectedSeat is String) {
                                setState(() => _seatController.text = selectedSeat);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Assento',
                              prefixIcon: Icon(Icons.event_seat),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _depositController,
                            inputFormatters: [_currencyFormatter],
                            keyboardType: TextInputType.number,
                            onChanged: _onDepositChanged, // Correção automática aqui
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Valor Pago',
                              prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.successColor),
                              helperText: widget.excursionPrice != null
                                  ? 'Máx: R\$ ${widget.excursionPrice!.toStringAsFixed(2)}'
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_isMinor) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      context,
                      Icons.family_restroom_outlined,
                      'Responsável Legal (Menor)',
                      color: Colors.amber,
                    ),
                    TextFormField(
                      controller: _guardianNameController,
                      decoration: const InputDecoration(labelText: 'Nome do Responsável'),
                      validator: (v) => _isMinor && v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _guardianPhoneController,
                      inputFormatters: [_phoneMask],
                      decoration: const InputDecoration(labelText: 'Contato Responsável'),
                      validator: (v) => _isMinor && v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ],

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(
                      widget.passenger == null ? 'FINALIZAR CADASTRO' : 'SALVAR ALTERAÇÕES',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateField(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _selectedBirthDate = date);
          _calculateAge(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Nascimento'),
        child: Text(
          _selectedBirthDate == null
              ? '--/--/----'
              : "${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}",
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
