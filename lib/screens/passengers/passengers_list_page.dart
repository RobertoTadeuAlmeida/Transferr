import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/widgets/passenger_card.dart'; // Renomeie seu ClientCard para PassengerCard
import 'add_passenger_page.dart';

class PassengersListPage extends StatelessWidget {
  final String excursionId;

  const PassengersListPage({super.key, required this.excursionId});

  @override
  Widget build(BuildContext context) {
    final excursionProvider = context.read<ExcursionProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Passageiros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar passageiro...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Lógica de busca pode ser implementada via local state ou provider
              },
            ),
          ),
          Expanded(
            // Usamos um StreamBuilder para ouvir os passageiros da sub-coleção 'vagas' em tempo real
            child: StreamBuilder<List<Passenger>>(
              stream: excursionProvider.getPassengersStream(excursionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar passageiros: ${snapshot.error}'));
                }

                final passengers = snapshot.data ?? [];

                if (passengers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Nenhum passageiro confirmado para esta viagem.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  itemCount: passengers.length,
                  itemBuilder: (context, index) {
                    final passenger = passengers[index];
                    return PassengerCard(
                      passenger: passenger,
                      onTap: () {
                        // Navegar para detalhes ou abrir check-in
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPassengerPage(excursionId: excursionId),
            ),
          );
        },
        label: const Text('Adicionar Passageiro'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}