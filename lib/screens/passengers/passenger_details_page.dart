import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/passenger_provider.dart';
import '../../models/passenger.dart';
import '../../models/enums.dart';
import 'add_passenger_page.dart';

class PassengerDetailsPage extends StatelessWidget {
  // excursionId agora é opcional, pois o passageiro pode estar na "Base Geral"
  final String? excursionId;
  final Passenger passenger;

  const PassengerDetailsPage({
    super.key,
    this.excursionId,
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? 'sistema';

    // Verifica se o passageiro está vinculado a alguma excursão no momento
    final bool isInExcursion = passenger.excursionId != null && passenger.excursionId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Passageiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddPassengerPage(
                  excursionId: excursionId ?? '',
                  passenger: passenger,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SÓ MOSTRA O STATUS DE EMBARQUE SE ESTIVER EM UMA EXCURSÃO
            if (isInExcursion) ...[
              _buildStatusCard(context, currentUserId),
              const SizedBox(height: 16),
            ],

            // CARD DADOS PESSOAIS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Dados do Viajante', style: textTheme.titleLarge),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDetailRow('Nome:', passenger.name, context),
                    _buildDetailRow('Documento:', passenger.document, context),
                    _buildDetailRow('WhatsApp:', passenger.phone, context),

                    // Poltrona só faz sentido se estiver em excursão
                    if (isInExcursion)
                      _buildDetailRow('Poltrona:', passenger.seatNumber ?? 'Não definida', context),

                    _buildDetailRow(
                      'Nascimento:',
                      DateFormat('dd/MM/yyyy').format(passenger.birthDate),
                      context,
                    ),
                    _buildDetailRow('Idade:', '${passenger.age} anos', context),

                    // EXIBIÇÃO DO SINAL PAGO (NOVA REGRA)
                    if (isInExcursion) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        'Sinal Pago:',
                        'R\$ ${passenger.depositValue.toStringAsFixed(2)}',
                        context,
                        valueColor: Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SEÇÃO DO RESPONSÁVEL
            if (passenger.isMinor && passenger.guardian != null)
              Card(
                color: Colors.orange.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.orange, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.family_restroom, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('Responsável Legal',
                              style: textTheme.titleLarge?.copyWith(color: Colors.orange)),
                        ],
                      ),
                      const Divider(height: 32, color: Colors.orange),
                      _buildDetailRow('Nome:', passenger.guardian!.name, context),
                      _buildDetailRow('Documento:', passenger.guardian!.document, context),
                      _buildDetailRow('Contato:', passenger.guardian!.phone, context),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // BOTÃO DE EXCLUSÃO
            Center(
              child: TextButton.icon(
                onPressed: () => _confirmDeletion(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remover do Sistema', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String currentUserId) {
    final status = passenger.statusEmbarque;

    return Card(
      color: status.color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: status.color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(status.icon, color: status.color),
        title: const Text('Status de Embarque'),
        subtitle: Text(
          status.label.toUpperCase(),
          style: TextStyle(color: status.color, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        trailing: const Icon(Icons.swap_vert),
        onTap: () => _showStatusPicker(context, currentUserId),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, String currentUserId) {
    final provider = context.read<PassengerProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BoardingStatus.values.map((s) {
            return ListTile(
              leading: Icon(s.icon, color: s.color),
              title: Text(s.label),
              trailing: passenger.statusEmbarque == s ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () async {
                // CORREÇÃO: Removido excursionId pois o provider não espera mais ele aqui
                await provider.updateBoardingStatus(
                  passengerId: passenger.id,
                  status: s,
                  agenteId: currentUserId,
                );
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Passageiro?'),
        content: Text('Isso removerá ${passenger.name} permanentemente do banco de dados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<PassengerProvider>().deletePassenger(passenger.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context, {Color? valueColor}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.bold : null
                )
            ),
          ),
        ],
      ),
    );
  }
}