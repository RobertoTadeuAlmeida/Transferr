import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // NECESSÁRIO para formatar datas e moedas
import 'package:provider/provider.dart';
import 'package:transferr/utils/extensions.dart'; // NECESSÁRIO para capitalizar o status
import '../../models/enums.dart';
import '../../models/excursion.dart';
import '../../providers/excursion_provider.dart';
import 'add_edit_excursion_page.dart';

class ExcursionDetailsPage extends StatelessWidget {
  final String excursionId;

  const ExcursionDetailsPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    // Usamos 'read' no build para pegar o provider uma vez
    final provider = context.read<ExcursionProvider>();
    // Usamos 'select' para ouvir APENAS as mudanças na excursão específica.
    // Isso é muito mais eficiente do que reconstruir a tela inteira.
    final Excursion? excursion = context.select<ExcursionProvider, Excursion?>(
          (p) => p.getExcursionById(excursionId),
    );

    if (excursion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Excursão não encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(excursion.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // 3. Botão de editar está no lugar certo agora
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditExcursionPage(excursion: excursion),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              context: context,
              title: 'Detalhes da Excursão',
              details: {
                // 1. CORRIGIDO: Usei 'location' em vez do 'description' que não existe
                'Local:': excursion.location,
                'Data:': DateFormat('dd/MM/yyyy').format(excursion.date),
                'Preço:': NumberFormat.simpleCurrency(locale: 'pt_BR').format(excursion.price),
                // 4. CORRIGIDO: Exibe o status de forma amigável
                'Status:': excursion.status.name.capitalize(),
              },
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              context: context,
              title: 'Resumo Financeiro',
              details: {
                'Clientes Confirmados:': '${excursion.totalClientsConfirmed}',
                'Renda Bruta:': NumberFormat.simpleCurrency(locale: 'pt_BR').format(excursion.grossRevenue),
                'Renda Líquida (Est.):': NumberFormat.simpleCurrency(locale: 'pt_BR').format(excursion.netRevenue),
              },
            ),
            const SizedBox(height: 20),
            _buildParticipantsCard(context, excursion),
            // 3. Botão de Editar foi movido para o AppBar, então este não é mais necessário
          ],
        ),
      ),
    );
  }

  // 5. Widget refatorado para evitar repetição de código
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Map<String, String> details,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ...details.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(BuildContext context, Excursion excursion) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participantes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.orangeAccent),
                  onPressed: () {
                    // TODO: Implementar tela específica para adicionar/gerenciar participantes
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tela de gerenciamento de participantes em breve!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (excursion.participants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('Nenhum participante cadastrado.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: excursion.participants.length,
                itemBuilder: (ctx, index) {
                  final participant = excursion.participants[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      // 2. CORRIGIDO: Usa paymentStatus para ícones e cores
                      participant.paymentStatus == PaymentStatus.paid ? Icons.check_circle : Icons.hourglass_top_rounded,
                      color: participant.paymentStatus == PaymentStatus.paid ? Colors.greenAccent : Colors.amberAccent,
                    ),
                    // 2. CORRIGIDO: Usa 'name' do participante
                    title: Text(participant.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    trailing: Text(
                      // 4. CORRIGIDO: Exibe o status de pagamento de forma amigável
                      participant.paymentStatus.name.capitalize(),
                      style: TextStyle(
                        color: participant.paymentStatus == PaymentStatus.paid ? Colors.greenAccent : Colors.amberAccent,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

