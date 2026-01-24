import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/passenger.dart';
import '../../providers/passenger_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../config/theme/app_theme.dart'; // Importando seu AppTheme
import 'passenger_details_page.dart';

class GlobalPassengersPage extends StatefulWidget {
  const GlobalPassengersPage({super.key});

  @override
  State<GlobalPassengersPage> createState() => _GlobalPassengersPageState();
}

class _GlobalPassengersPageState extends State<GlobalPassengersPage> {
  String _searchQuery = '';
  late Future<List<Passenger>> _passengersFuture;

  @override
  void initState() {
    super.initState();
    // Resolve o erro de build usando microtask
    _passengersFuture = Future.microtask(() =>
        context.read<PassengerProvider>().getAllPassengers()
    );
  }

  void _refreshList() {
    setState(() {
      _passengersFuture = context.read<PassengerProvider>().getAllPassengers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor já definido no seu AppTheme (scaffoldBackgroundColor)
      appBar: AppBar(
        title: const Text('Base de Passageiros'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: FutureBuilder<List<Passenger>>(
              future: _passengersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar dados',
                        style: TextStyle(color: AppTheme.errorColor)),
                  );
                }

                final passengers = snapshot.data ?? [];
                final filtered = passengers
                    .where((p) => p.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Nenhum passageiro encontrado na base.'),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async => _refreshList(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final bool isTraveling = p.excursionId != null && p.excursionId!.isNotEmpty;

                      return Card(
                        // CardTheme do seu AppTheme já aplica a cor e bordas
                        child: ListTile(
                          // listTileTheme do seu AppTheme já cuida da cor do ícone
                          leading: CircleAvatar(
                            backgroundColor: isTraveling
                                ? AppTheme.successColor.withAlpha(30)
                                : theme.primaryColor.withAlpha(20),
                            child: Icon(
                              isTraveling ? Icons.bus_alert : Icons.person_outline,
                              color: isTraveling ? AppTheme.successColor : theme.primaryColor,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isTraveling ? 'Em viagem ativa' : 'Histórico de passageiro',
                            style: TextStyle(
                              color: isTraveling ? AppTheme.successColor : Colors.white70,
                            ),
                          ),
                          trailing: _buildTripCounter(p.totalTrips, theme),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PassengerDetailsPage(passenger: p),
                            ),
                          ).then((_) => _refreshList()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCounter(int count, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'VIAGENS',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        // inputDecorationTheme do AppTheme já cuida do fill e border
        decoration: const InputDecoration(
          hintText: 'Buscar na base de clientes...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }
}