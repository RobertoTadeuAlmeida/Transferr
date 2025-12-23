import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/screens/excursions/participant_detail_page.dart';
import 'package:transferr/utils/extensions.dart'; // Verifique o caminho
import '../../../models/enums.dart';
import '../../../models/excursion.dart';
import '../../../models/participant.dart';
import '../../../providers/excursion_provider.dart';

class ParticipantsSection extends StatelessWidget {
  final Excursion excursion;
  const ParticipantsSection({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Participantes (${excursion.participants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        if (excursion.participants.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('Nenhum participante adicionado ainda.\nUse o botão + para começar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ),
          )
        else
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: excursion.participants.length,
              padding: EdgeInsets.zero,
              itemBuilder: (ctx, index) {
                final participant = excursion.participants[index];
                final IconData statusIcon;
                final Color statusColor;

                switch (participant.paymentStatus) {
                  case PaymentStatus.paid:
                    statusIcon = Icons.check_circle;
                    statusColor = Colors.greenAccent;
                    break;
                  case PaymentStatus.free:
                    statusIcon = Icons.celebration;
                    statusColor = Colors.yellowAccent;
                    break;
                  default: // pending, partial
                    statusIcon = Icons.person_outline;
                    statusColor = const Color(0xFFF97316);
                }
                return ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(participant.name),
                  subtitle: Text('Pagamento: ${participant.paymentStatus.name.capitalize()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    tooltip: 'Remover Participante',
                    onPressed: () => _removeParticipant(context, excursion, participant),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ParticipantDetailPage(
                          excursionId: excursion.id!,
                          initialParticipant: participant,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _removeParticipant(BuildContext context, Excursion excursion, Participant participant) async {
    final provider = context.read<ExcursionProvider>();
    final bool? confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover Participante'),
        content: Text('Tem certeza que deseja remover "${participant.name}" desta excursão?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.removeParticipantFromExcursion(excursionId: excursion.id!, participant: participant);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover participante: $e')));
      }
    }
  }
}
