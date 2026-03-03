import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:transferr/firebase_options.dart';

// Providers
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/screens/finance/excursion_finance_page.dart';

// Screens
import 'package:transferr/screens/register/registration_page.dart';
import 'package:transferr/screens/login/auth_wrapper.dart';
import 'package:transferr/screens/home_page.dart';
import 'package:transferr/screens/excursions/excursions_page.dart';
import 'package:transferr/screens/excursions/excursion_dashboard_page.dart';
import 'package:transferr/screens/excursions/add_excursion_page.dart';
import 'package:transferr/screens/excursions/excursion_seat_map_page.dart';
import 'package:transferr/screens/excursions/checkin_page.dart';
import 'package:transferr/screens/passengers/add_passenger_page.dart';
import 'package:transferr/screens/passengers/global_passengers_page.dart';
import 'package:transferr/screens/passengers/passengers_list_page.dart';
import 'package:transferr/screens/passengers/passenger_details_page.dart'; // Importado
import 'package:transferr/screens/settings/settings_page.dart';
import 'package:transferr/screens/finance/finance_page.dart';
import 'package:transferr/screens/users/users_list_page.dart';

import 'config/theme/app_theme.dart';
import 'models/excursion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExcursionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PassengerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transferr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',

      routes: {
        // --- Fluxo de Autenticação ---
        '/': (context) => const AuthWrapper(),
        '/register': (context) => const RegistrationPage(),

        // --- Painel Principal ---
        '/home': (context) => const HomePage(),

        // --- Fluxo de Excursões ---
        '/excursions': (context) => const ExcursionsPage(),
        '/add-excursion': (context) => const AddExcursionPage(),

        '/excursion-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ExcursionDashboardPage(excursionId: args);
          }
          return _errorPage("ID da excursão não encontrado para o Dashboard");
        },

        '/map-seats': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return ExcursionSeatMapPage(
              excursionId: args['excursionId'],
              totalSeats: args['totalSeats'] ?? 44,
            );
          } else if (args is String) {
            return ExcursionSeatMapPage(excursionId: args);
          }
          return _errorPage(
            "ID da excursão não informado para o mapa de assentos",
          );
        },

        '/check-in': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return CheckInPage(
              excursionId: args['excursionId'],
              destinationName:
                  args['destinationName'] ?? 'Destino não informado',
            );
          }
          return _errorPage("Dados da excursão incompletos para o Check-in");
        },

        // --- Fluxo de Passageiros ---
        '/global-passengers': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return GlobalPassengersPage(excursionId: args['excursionId']);
          }
          return const GlobalPassengersPage();
        },

        '/passengers-list': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return PassengersListPage(excursionId: args);
          }
          return _errorPage("ID da excursão não informado para lista");
        },

        '/add-passenger': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return AddPassengerPage(
              excursionId: args['excursionId'],
              excursionPrice: args['excursionPrice'],
              passenger: args['passenger'],
            );
          }
          if (args is String) {
            return AddPassengerPage(excursionId: args);
          }
          return _errorPage(
            "Parâmetros insuficientes para adicionar passageiro",
          );
        },

        '/passenger-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return PassengerDetailsPage(
              passenger: args['passenger'],
              excursionId: args['excursionId'],
            );
          }
          return _errorPage(
            "Dados do passageiro não encontrados para detalhes",
          );
        },

        // --- Financeiro da excursão --- //
        '/excursion-finance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Excursion) {
            return ExcursionFinancePage(excursion: args);
          }
          return _errorPage(
            "Dados da excursão não encontrados para a planilha financeira",
          );
        },

        // --- Gestão e Configurações ---
        '/users': (context) => const UsersListPage(),
        '/finance': (context) => const FinancePage(),
        '/settings': (context) => const SettingsPage(),
      },

      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  Widget _errorPage(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erro de Navegação")),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
