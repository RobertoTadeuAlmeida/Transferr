import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/enums.dart';
import 'package:transferr/models/participant.dart';
import 'package:transferr/providers/excursion_provider.dart';

// Classe que traduz o enum para nomes amigáveis
extension PaymentStatusName on PaymentStatus {
  String get displayName {
    return switch (this) {
      PaymentStatus.paid => 'Pago',
      PaymentStatus.partial => 'Parcial',
      PaymentStatus.pending => 'Pendente',
      PaymentStatus.free => 'Cortesia',
    };
  }
}

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
  late final TextEditingController _amountPaidController;
  late PaymentStatus _selectedPaymentStatus;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ExcursionProvider>();
    final newAmount = double.tryParse(_amountPaidController.text.replaceAll(',', '.')) ?? 0.0;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      // O AlertDialog agora é totalmente estilizado pelo dialogTheme
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Alterações'),
        content: const Text('Deseja salvar as alterações de pagamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          // O FilledButton herda o estilo principal do tema
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.updateParticipantPayment(
        excursionId: widget.excursionId,
        oldParticipant: widget.initialParticipant,
        newStatus: _selectedPaymentStatus,
        newAmount: newAmount,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        // A SnackBar usa o tema e a cor de erro dele
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // O AppBar já é estilizado pelo tema
      appBar: AppBar(
        title: Text(widget.initialParticipant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_rounded),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Gerenciar Pagamento', style: textTheme.headlineSmall),
              const Divider(height: 24, color: Colors.white24),

              // O TextFormField usa o inputDecorationTheme do tema global
              TextFormField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Valor Pago',
                  prefixText: 'R\$ ',
                  // Não precisa mais de 'border', pois vem do tema
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Insira um valor.';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // O DropdownButtonFormField também usa o inputDecorationTheme
              DropdownButtonFormField<PaymentStatus>(
                value: _selectedPaymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Status do Pagamento',
                ),
                // O menu suspenso usa o dropdownMenuTheme
                items: PaymentStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName), // Usa a extensão para nome amigável
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

              // O FilledButton não precisa mais de estilo local
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
                onPressed: _submitPaymentUpdate,
                // O padding e textStyle já são definidos no elevatedButtonTheme
              ),
            ],
          ),
        ),
      ),
    );
  }
}
