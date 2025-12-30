import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 1. Importar o tema
import 'package:transferr/screens/excursions/participant_detail_page.dart';
import 'package:transferr/utils/extensions.dart';
import '../../../models/enums.dart';
import '../../../models/excursion.dart';
import '../../../models/participant.dart';
import '../../../providers/excursion_provider.dart';

class ParticipantsSection extends StatelessWidget {
  final Excursion excursion;
  const ParticipantsSection({super.key, required this.excursion});

  @override
  Widget build(BuildContext context) {
    // 2. Acesso ao tema para cores e estilos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3. Título da seção usa o textTheme
        Text(
          'Participantes (${excursion.participants.length})',
          style: textTheme.titleLarge,
        ),
        const Divider(height: 24), // O Divider já usa as cores do tema
        if (excursion.participants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              // 4. Texto de fallback usa o textTheme
              child: Text(
                'Nenhum participante adicionado ainda.\nUse o botão + para começar.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ),
          )
        else
          Card(
            // O Card usa o cardTheme para estilo e margens
            margin: EdgeInsets.zero, // Remove margem extra dentro da coluna
            clipBehavior: Clip.antiAlias, // Garante que o conteúdo respeite as bordas arredondadas
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: excursion.participants.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, index) {
                final participant = excursion.participants[index];

                // 5. Cores de status vêm do tema
                final (IconData statusIcon, Color statusColor) = switch (participant.paymentStatus) {
                  PaymentStatus.paid => (Icons.check_circle_outline, AppTheme.successColor),
                  PaymentStatus.free => (Icons.celebration_outlined, AppTheme.warningColor),
                  _ => (Icons.person_outline, theme.primaryColor),
                };

                return ListTile(
                  // 6. O ListTile usa o listTileTheme
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(participant.name),
                  subtitle: Text('Pagamento: ${participant.paymentStatus.name.capitalize()}'),
                  trailing: IconButton(
                    // O ícone de remover usa a cor de erro do tema
                    icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
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

    // 7. O AlertDialog e seus botões usam o tema
    final bool? confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover Participante'),
        content: Text('Tem certeza que deseja remover "${participant.name}" desta excursão?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            // O botão de remover usa a cor de erro do tema
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.removeParticipantFromExcursion(excursionId: excursion.id!, participant: participant);
      } catch (e) {
        // A SnackBar de erro usa o tema
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover participante: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
