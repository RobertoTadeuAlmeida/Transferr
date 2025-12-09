import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import '../../models/excursion.dart';
import '../../providers/excursion_provider.dart';

class AddEditExcursionPage extends StatefulWidget {
  // A excursão pode ser nula se estivermos criando uma nova
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

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa os controllers com os dados da excursão se estiver editando
    final excursion = widget.excursion;
    _nameController = TextEditingController(text: excursion?.name ?? '');
    _priceController = TextEditingController(
      text: excursion?.price.toString() ?? '',
    );
    _totalSeatsController = TextEditingController(
      text: excursion?.totalSeats.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: excursion?.location ?? '',
    );

    if (excursion != null) {
      _selectedDate = excursion.date;
      _dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(excursion.date),
      );
    } else {
      _dateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Limpa os controllers para liberar memória
    _nameController.dispose();
    _priceController.dispose();
    _totalSeatsController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- LÓGICA PRINCIPAL DE SALVAMENTO ---
  Future<void> _saveExcursion() async {
    // 1. Valida o formulário e verifica se a data foi selecionada.
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione uma data para a excursão.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; // Para a execução se algo estiver inválido.
    }

    setState(() => _isLoading = true);

    await Future.delayed(Duration.zero);


    final provider = context.read<ExcursionProvider>();

    try {
      // 2. Cria o objeto Excursion com os dados corretos.
      //    A verificação do _selectedDate já foi feita acima, então podemos usar '!' com segurança.
      final excursionData = Excursion(
        id: widget.excursion?.id,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        totalSeats: int.tryParse(_totalSeatsController.text) ?? 0,
        date: _selectedDate!, // CORRETO: Usa a variável DateTime.
        location: _locationController.text.trim(),
        // O status e os participantes usarão os valores padrão do modelo.
      );

      // 3. Chama o método do provider para salvar no Firebase.
      if (widget.excursion == null) {
        await provider.addExcursion(excursionData);
      } else {
        await provider.updateExcursion(excursionData);
      }

      // 4. Se tudo deu certo, fecha a tela e mostra sucesso.
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excursão salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar excursão: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // Função para abrir o seletor de data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Formata a data para exibir no campo de texto
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.excursion == null ? 'Nova Excursão' : 'Editar Excursão',
        ),
        actions: [
          // Adiciona o botão de salvar na barra do AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _saveExcursion,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nome da Excursão',
                icon: Icons.tour,
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira um nome' : null,
              ),
              _buildTextFormField(
                controller: _dateController,
                labelText: 'Data da Excursão',
                icon: Icons.calendar_today,
                readOnly: true,
                // Impede a digitação manual
                onTap: () => _selectDate(context),
                // Abre o seletor de data
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, selecione uma data' : null,
              ),
              _buildTextFormField(
                controller: _locationController,
                labelText: 'Local de Saída',
                icon: Icons.location_on,
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira um local' : null,
              ),
              _buildTextFormField(
                controller: _priceController,
                labelText: 'Preço por Pessoa (R\$)',
                icon: Icons.monetization_on,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira um preço' : null,
              ),
              _buildTextFormField(
                controller: _totalSeatsController,
                labelText: 'Total de Assentos',
                icon: Icons.event_seat,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty
                    ? 'Por favor, insira o total de assentos'
                    : null,
              ),

              // Adicione mais campos aqui se necessário...
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir os campos de texto e evitar repetição
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function()? onTap,
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
        ),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
      ),
    );
  }
}
