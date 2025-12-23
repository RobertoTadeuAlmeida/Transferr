import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../models/participant.dart';
import '../../providers/excursion_provider.dart';

class ParticipantDetailPage extends StatefulWidget {
  final String excursionId;
  final Participant initialParticipant;

  const ParticipantDetailPage({
    super.key,
    required this.excursionId,
    required this.initialParticipant,
  });

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  // Controladores para o formulário
  late final TextEditingController _amountPaidController;
  late PaymentStatus _selectedPaymentStatus;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inicializa o estado do formulário com os dados atuais do participante
    _amountPaidController = TextEditingController(
      text: widget.initialParticipant.amountPaid.toStringAsFixed(2),
    );
    _selectedPaymentStatus = widget.initialParticipant.paymentStatus;
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _submitPaymentUpdate() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ExcursionProvider>();
    final newAmount = double.tryParse(_amountPaidController.text) ?? 0.0;

    // Pede confirmação ao usuário
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Atualização'),
        content: const Text('Deseja salvar as alterações de pagamento para este participante?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Chama o método no provider que fará a mágica
      await provider.updateParticipantPayment(
        excursionId: widget.excursionId,
        oldParticipant: widget.initialParticipant,
        newStatus: _selectedPaymentStatus,
        newAmount: newAmount,
      );

      // Volta para a tela anterior se tudo der certo
      Navigator.of(context).pop();

    } catch (e) {
      // Mostra um erro se algo falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar pagamento: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialParticipant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitPaymentUpdate,
            tooltip: 'Salvar Alterações',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gerenciar Pagamento', style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 24),

              // --- CAMPO VALOR PAGO ---
              TextFormField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Valor Pago',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- SELETOR DE STATUS DE PAGAMENTO ---
              DropdownButtonFormField<PaymentStatus>(
                value: _selectedPaymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Status do Pagamento',
                  border: OutlineInputBorder(),
                ),
                items: PaymentStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    // Deixa os nomes mais amigáveis
                    child: Text(status.name == 'pending' ? 'Pendente' : (status.name == 'partial' ? 'Parcial' : 'Pago')),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Alterações'),
                  onPressed: _submitPaymentUpdate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
