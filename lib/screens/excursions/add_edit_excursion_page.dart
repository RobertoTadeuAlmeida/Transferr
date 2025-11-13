import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/excursion_provider.dart';

import '../../models/excursion.dart';

class AddEditExcursionPage extends StatefulWidget {
  // Se 'excursion' for nulo, estamos criando uma nova.
  // Se não, estamos editando uma existente.
  final Excursion? excursion;

  const AddEditExcursionPage({super.key, this.excursion});

  @override
  State<AddEditExcursionPage> createState() => _AddEditExcursionPageState();
}

class _AddEditExcursionPageState extends State<AddEditExcursionPage> {
  // Uma GlobalKey para identificar e validar nosso formulário.
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar o input do usuário.
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _totalSeatsController;

  // Variável para guardar a data selecionada.
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.excursion != null;

  @override
  void initState() {
    super.initState();

    // Inicializa os controladores com os valores da excursão, se estiver editando.
    _nameController = TextEditingController(text: widget.excursion?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.excursion?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.excursion?.price.toString() ?? '0.0',
    );
    _totalSeatsController = TextEditingController(
      text: widget.excursion?.totalSeats.toString() ?? '0',
    );
    _selectedDate = widget.excursion?.date ?? DateTime.now();
  }

  // Libera os recursos dos controladores quando o widget é descartado.
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  // Função para mostrar o seletor de data (DatePicker).
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Função para salvar o formulário.
  void _saveForm() {
    // Primeiro, valida se todos os campos do formulário estão corretos.
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ExcursionProvider>(context, listen: false);

      // Converte os valores dos controladores para os tipos corretos.
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final totalSeats = int.tryParse(_totalSeatsController.text) ?? 0;

      try {
        if (_isEditing) {
          // Modo Edição: cria uma cópia da excursão existente com os novos dados.
          final updatedExcursion = widget.excursion!.copyWith(
            name: _nameController.text,
            description: _descriptionController.text,
            date: _selectedDate,
            price: price,
            totalSeats: totalSeats,
          );
          provider.updateExcursion(updatedExcursion);
        } else {
          // Modo Adicionar: cria uma nova instância de Excursion.
          final newExcursion = Excursion(
            id: '',
            // O Firestore cuidará de gerar o ID.
            name: _nameController.text,
            description: _descriptionController.text,
            date: _selectedDate,
            price: price,
            totalSeats: totalSeats,
            participants: [],
            location: '',
            status: ExcursionStatus.agendada,
          );
          provider.addExcursion(newExcursion);
        }
        // Volta para a tela anterior após salvar.
        Navigator.of(context).pop();
      } catch (error) {
        // Mostra uma mensagem de erro se algo der errado.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar excursão: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Excursão' : 'Nova Excursão'),
        // Adiciona o botão de salvar diretamente na AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
            tooltip: 'Salvar',
          ),
        ],
      ),
      // Usa um SingleChildScrollView para evitar que o teclado cubra os campos.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Campo Nome ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Excursão',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um nome.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Descrição ---
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.article_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // --- Seletor de Data ---
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data da Excursão',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Alterar'),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // --- Linha para Preço e Vagas ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Campo Preço ---
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço (R\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // --- Campo Vagas Totais ---
                    Expanded(
                      child: TextFormField(
                        controller: _totalSeatsController,
                        decoration: const InputDecoration(
                          labelText: 'Vagas Totais',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
