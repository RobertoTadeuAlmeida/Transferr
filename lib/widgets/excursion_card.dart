import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transferr/config/theme/app_theme.dart'; // 1. Importar o tema
import '../models/excursion.dart';
import '../models/enums.dart';
import '../providers/excursion_provider.dart';
import '../screens/excursions/excursion_dashboard_page.dart';

class ExcursionCard extends StatelessWidget {
  final Excursion excursion;
  final bool showFeaturedStar;
  final bool actionsEnabled;
  final bool isInsideListTile;
  final bool isSelected; // 2. Adicionar o parâmetro de seleção

  const ExcursionCard({
    super.key,
    required this.excursion,
    this.showFeaturedStar = true,
    this.actionsEnabled = true,
    this.isInsideListTile = false,
    this.isSelected = false, // 3. Valor padrão
  });

  @override
  Widget build(BuildContext context) {
    // 4. Usar o tema para cores e textos
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Lógica de cor e ícone para o status
    final (Color statusColor, IconData statusIcon) = switch (excursion.status) {
      ExcursionStatus.realizada => (AppTheme.successColor, Icons.check_circle_outline),
      ExcursionStatus.cancelada => (theme.colorScheme.error, Icons.cancel_outlined),
      _ => (AppTheme.infoColor, Icons.schedule),
    };

    final cardContent = Padding(
      // Padding interno do conteúdo, não do Card em si
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  excursion.name,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showFeaturedStar && actionsEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    excursion.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                    color: excursion.isFeatured ? Colors.amber.shade600 : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_outlined,
            text: DateFormat('dd/MM/yyyy').format(excursion.date),
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            context,
            icon: Icons.people_alt_outlined,
            text: '${excursion.participants.length} de ${excursion.totalSeats} vagas',
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            context,
            icon: statusIcon,
            text: excursion.status.name,
            color: statusColor,
          ),
        ],
      ),
    );

    // Se estiver dentro de um ListTile, retorna apenas o conteúdo.
    // O ListTile pai controlará o clique.
    if (isInsideListTile) {
      return cardContent;
    }

    // Comportamento original: um Card clicável.
    return Card(
      // A forma agora inclui a borda de seleção
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2.0)
            : BorderSide.none,
      ),
      // O clique é desabilitado se as ações não estiverem ativas
      child: InkWell(
        onTap: actionsEnabled
            ? () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExcursionDashboardPage(excursionId: excursion.id!),
          ),
        )
            : null,
        borderRadius: BorderRadius.circular(12.0),
        child: cardContent,
      ),
    );
  }

  // Widget auxiliar para as linhas de detalhe, já usando o tema
  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String text, Color? color}) {
    final textTheme = Theme.of(context).textTheme;
    final defaultColor = textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? defaultColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(color: color ?? defaultColor),
        ),
      ],
    );
  }
}
