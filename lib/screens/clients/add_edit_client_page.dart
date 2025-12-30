import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../../models/client.dart';
import '../../../providers/client_provider.dart';
// Nenhum import de tema é necessário aqui, pois os estilos vêm do context.

class AddEditClientPage extends StatefulWidget {
  final Client? client;

  const AddEditClientPage({super.key, this.client});

  @override
  State<AddEditClientPage> createState() => _AddEditClientPageState();
}

class _AddEditClientPageState extends State<AddEditClientPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _cpfController;
  DateTime? _selectedBirthDate;

  bool _isLoading = false;

  // A lógica de máscaras e controllers permanece a mesma
  final _phoneMaskFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _cpfMaskFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _contactController = TextEditingController(text: _phoneMaskFormatter.maskText(widget.client?.contact ?? ''));
    _cpfController = TextEditingController(text: _cpfMaskFormatter.maskText(widget.client?.cpf ?? ''));
    _selectedBirthDate = widget.client?.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // A lógica de negócio (_selectBirthDate, _submitForm) permanece idêntica.
  // Apenas as SnackBars foram atualizadas para usar as cores do tema.
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedBirthDate != null) {
      setState(() => _isLoading = true);
      final isEditing = widget.client != null;
      try {
        final clientData = Client(
          id: widget.client?.id ?? '',
          name: _nameController.text.trim(),
          contact: _phoneMaskFormatter.getUnmaskedText(),
          cpf: _cpfMaskFormatter.getUnmaskedText(),
          birthDate: _selectedBirthDate!,
          confirmedExcursionIds: widget.client?.confirmedExcursionIds ?? [],
          pendingExcursionIds: widget.client?.pendingExcursionIds ?? [],
        );

        final provider = context.read<ClientProvider>();
        if (isEditing) {
          await provider.updateClient(clientData);
        } else {
          await provider.addClient(clientData);
        }

        if (mounted) {
          final successMessage = isEditing ? 'Cliente atualizado!' : 'Cliente adicionado!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Theme.of(context).colorScheme.secondary, // Usando cor do tema
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Theme.of(context).colorScheme.error, // Usando cor de erro do tema
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione a data de nascimento.'),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.8), // Usando cor de aviso do tema
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;
    final textTheme = Theme.of(context).textTheme; // Acesso fácil aos estilos de texto

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Adicionar Cliente'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save_alt_rounded),
              tooltip: 'Salvar',
              onPressed: _submitForm,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Os TextFormFields agora usam a decoração padrão do tema
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'O nome é obrigatório.' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                inputFormatters: [_phoneMaskFormatter],
                decoration: const InputDecoration(labelText: 'Telefone com DDD', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final numbers = _phoneMaskFormatter.getUnmaskedText();
                  if (numbers.isEmpty) return 'O contato é obrigatório.';
                  if (numbers.length < 10) return 'Número de telefone incompleto.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                inputFormatters: [_cpfMaskFormatter],
                decoration: const InputDecoration(labelText: 'CPF', prefixIcon: Icon(Icons.badge_outlined)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final numbers = _cpfMaskFormatter.getUnmaskedText();
                  if (numbers.isEmpty) return 'O CPF é obrigatório.';
                  if (numbers.length < 11) return 'CPF incompleto.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // O ListTile agora usa as cores e formas do tema
              ListTile(
                leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                title: Text(
                  _selectedBirthDate == null
                      ? 'Selecione a Data de Nascimento *'
                      : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)}',
                  style: textTheme.bodyLarge,
                ),
                onTap: () => _selectBirthDate(context),
                tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                shape: Theme.of(context).inputDecorationTheme.border?.toOutlineInputBorder(),
              ),
              const SizedBox(height: 32),
              // O ElevatedButton agora usa o estilo padrão do tema
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _submitForm,
                label: const Text('Salvar Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on InputBorder? {
  OutlineInputBorder? toOutlineInputBorder() {
    if (this is OutlineInputBorder) {
      return this as OutlineInputBorder;
    }
    return null;
  }
}

