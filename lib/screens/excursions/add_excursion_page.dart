import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart';
import '../../models/excursion.dart';
import '../../models/enums.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/auth_provider.dart';

class AddExcursionPage extends StatefulWidget {
  final Excursion? excursion;

  const AddExcursionPage({super.key, this.excursion});

  @override
  State<AddExcursionPage> createState() => _AddExcursionPageState();
}

class _AddExcursionPageState extends State<AddExcursionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _destIdController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  String _currentSlug = '';

  late DateTime _startDate;
  late DateTime _returnDate;
  bool _isLoading = false;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    final e = widget.excursion;

    _nameController = TextEditingController(text: e?.name ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _destIdController = TextEditingController(text: e?.idMainDestination ?? '');

    _priceController = TextEditingController(
      text: e != null ? _currencyFormatter.format(e.basePrice) : '',
    );
    _seatsController = TextEditingController(
      text: e?.totalSeats.toString() ?? '44',
    );

    _currentSlug = e?.slug ?? '';
    _startDate = e?.startDate ?? DateTime.now().add(const Duration(days: 7));
    _returnDate = e?.returnDate ?? DateTime.now().add(const Duration(days: 9));
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _returnDate),
      );
      if (time != null) {
        setState(() {
          final newDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
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

    try {
      final authProvider = context.read<AuthProvider>();
      final excursionProvider = context.read<ExcursionProvider>();

      // TENTA RECUPERAR A EMPRESA DE MÚLTIPLAS FONTES
      String activeCompanyId = authProvider.currentUser?.company ?? '';

      // Se o Auth ainda não carregou, tenta pegar o que o Provider de Excursões está vigiando
      if (activeCompanyId.isEmpty) {
        activeCompanyId = excursionProvider.currentCompanyId ?? '';
      }

      // Se for edição, usa a empresa original como última instância
      if (activeCompanyId.isEmpty && widget.excursion != null) {
        activeCompanyId = widget.excursion!.empresa;
      }

      if (activeCompanyId.isEmpty) {
        throw Exception("Não foi possível identificar sua empresa ativa.");
      }

      String plainValue = _priceController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final price = double.tryParse(plainValue) ?? 0.0;

      final excursion = Excursion(
        id: widget.excursion?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        idMainDestination: _destIdController.text.trim(),
        startDate: _startDate,
        returnDate: _returnDate,
        basePrice: price,
        totalSeats: int.tryParse(_seatsController.text) ?? 0,
        reservedSeats: widget.excursion?.reservedSeats ?? 0,
        slug: _currentSlug,
        status: widget.excursion?.status ?? ExcursionStatus.programada,
        idResponsible:
            widget.excursion?.idResponsible ??
            authProvider.currentUser?.id ??
            '',
        empresa: activeCompanyId,
      );

      if (widget.excursion == null) {
        await excursionProvider.addExcursion(excursion, activeCompanyId);
      } else {
        await excursionProvider.updateExcursion(excursion);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.excursion == null
                  ? 'Excursão criada!'
                  : 'Dados atualizados!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
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
    final isEditing = widget.excursion != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Excursão' : 'Nova Excursão'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  _buildSectionTitle("Informações Gerais"),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Excursão',
                      prefixIcon: Icon(
                        Icons.directions_bus,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onChanged: _updateSlug,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destIdController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade de Destino',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição / Roteiro',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Financeiro e Vagas"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: AppTheme.successColor,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _seatsController,
                          decoration: const InputDecoration(
                            labelText: 'Total de Vagas',
                            prefixIcon: Icon(
                              Icons.event_seat,
                              color: AppTheme.infoColor,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Cronograma"),
                  _buildDateTile(
                    'Partida',
                    _startDate,
                    () => _selectDateTime(context, true),
                  ),
                  _buildDateTile(
                    'Retorno',
                    _returnDate,
                    () => _selectDateTime(context, false),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing
                          ? AppTheme.infoColor
                          : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR EXCURSÃO',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy - HH:mm').format(date),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.edit_calendar, size: 20),
        onTap: onTap,
      ),
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    double value = double.parse(newValue.text);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
