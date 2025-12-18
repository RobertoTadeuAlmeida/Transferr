import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../../models/client.dart';
import '../../../providers/client_provider.dart';

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

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _cpfMaskFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _contactController = TextEditingController(
        text: _phoneMaskFormatter.maskText(widget.client?.contact ?? '')
    );
    _cpfController = TextEditingController(
        text: _cpfMaskFormatter.maskText(widget.client?.cpf ?? '')
    );

    _selectedBirthDate = widget.client?.birthDate;
  }


  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000), // Data inicial mais sensata
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
    // 1. Valida todos os campos do formulário com as novas regras
    if (_formKey.currentState!.validate() && _selectedBirthDate != null) {
      setState(() => _isLoading = true);

      final isEditing = widget.client != null;

      try {
        final unmaskedPhone = _phoneMaskFormatter.getUnmaskedText();
        final unmaskedCpf = _cpfMaskFormatter.getUnmaskedText();

        final clientData = Client(
          id: widget.client?.id ?? '',
          name: _nameController.text.trim(),
          contact: unmaskedPhone, // Salva apenas os números
          cpf: unmaskedCpf,       // Salva apenas os números
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
          final successMessage = isEditing ? 'Cliente atualizado com sucesso!' : 'Cliente adicionado com sucesso!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar cliente: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a data de nascimento.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Adicionar Cliente'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'O nome é obrigatório.' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                inputFormatters: [_phoneMaskFormatter],
                decoration: const InputDecoration(labelText: 'Telefone com DDD (somente números)', border: OutlineInputBorder(), prefixText: '+55 '),
                keyboardType: TextInputType.phone,
                validator: (value) {final numbers = _phoneMaskFormatter.getUnmaskedText();
                if (numbers.isEmpty) return 'O contato é obrigatório.';
                if (numbers.length < 10) return 'Número de telefone incompleto.';
                return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                inputFormatters: [_cpfMaskFormatter],
                decoration: const InputDecoration(labelText: 'CPF (somente números)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final numbers = _cpfMaskFormatter.getUnmaskedText();
                  if (numbers.isEmpty) return 'O CPF é obrigatório.';
                  if (numbers.length < 11) return 'CPF incompleto.';
                  // Aqui você ainda pode adicionar um algoritmo de validação real
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _selectedBirthDate == null
                      ? 'Selecione a Data de Nascimento *'
                      : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)}',
                ),
                onTap: () => _selectBirthDate(context),
                tileColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _submitForm,
                child: const Text('Salvar Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
