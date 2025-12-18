import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/excursion.dart';
import '../models/enums.dart';
import '../providers/excursion_provider.dart';
import '../screens/excursions/excursion_dashboard_page.dart';

class ExcursionCard extends StatelessWidget {
  final Excursion excursion;
  final bool showFeaturedStar;
  final bool actionsEnabled;
  final bool isInsideListTile;

  const ExcursionCard({
    super.key,
    required this.excursion,
    this.showFeaturedStar = true,
    this.actionsEnabled = true,
    this.isInsideListTile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Lógica para definir a cor do Chip de Status
    final status = excursion.status;
    final statusColor = switch (status) {
      ExcursionStatus.agendada => Colors.blue,
      ExcursionStatus.realizada => Colors.green,
      ExcursionStatus.cancelada => Colors.red,
      ExcursionStatus.confirmada => Colors.blue,
    };

    // O conteúdo do card que será reutilizado
    final cardContent = Stack(
      children: [
        // A coluna com todas as informações da excursão
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical
            children: [
              // Row superior agora só tem o título
              Text(
                excursion.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Row para Data
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(excursion.date)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row para Assentos
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    '${excursion.totalClientsConfirmed} de ${excursion.totalSeats} vagas preenchidas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Botão de "Destaque" (estrela) continua no canto superior direito
        if (showFeaturedStar && actionsEnabled)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                excursion.isFeatured ? Icons.star : Icons.star_border,
                color: excursion.isFeatured ? Colors.amber : Colors.grey,
              ),
              tooltip: 'Marcar como destaque',
              onPressed: () {
                context.read<ExcursionProvider>().toggleFeaturedStatus(
                  excursion.id!,
                  excursion.isFeatured,
                );
              },
            ),
          ),

        // CORREÇÃO 1 e 2: O Chip de Status agora está posicionado no canto inferior direito
        Positioned(
          bottom: 20,
          right: 8,
          child: Chip(
            label: Text(
              status.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            backgroundColor: statusColor,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );

    // Se estiver dentro de um ListTile, não renderiza o Card/InkWell externo
    if (isInsideListTile) {
      return cardContent;
    }

    // Comportamento original para a tela de excursões ativas
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: const Color(0xFF2A2A2A),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actionsEnabled
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ExcursionDashboardPage(excursionId: excursion.id!),
            ),
          );
        }
            : null,
        borderRadius: BorderRadius.circular(12.0),
        child: cardContent,
      ),
    );
  }
}
