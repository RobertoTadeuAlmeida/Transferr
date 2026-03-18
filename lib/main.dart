import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:transferr/firebase_options.dart';

// Providers
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/passenger_provider.dart';

// Screens
import 'package:transferr/screens/login/auth_wrapper.dart';
import 'package:transferr/screens/register/registration_page.dart';
import 'package:transferr/screens/home_page.dart';
import 'package:transferr/screens/settings/settings_page.dart';
import 'package:transferr/screens/settings/my_company_page.dart';
import 'package:transferr/screens/excursions/excursions_page.dart';
import 'package:transferr/screens/excursions/excursion_dashboard_page.dart';
import 'package:transferr/screens/excursions/add_excursion_page.dart';
import 'package:transferr/screens/excursions/excursion_seat_map_page.dart';
import 'package:transferr/screens/excursions/checkin_page.dart';
import 'package:transferr/screens/excursions/history_page.dart';
import 'package:transferr/screens/passengers/add_passenger_page.dart';
import 'package:transferr/screens/passengers/global_passengers_page.dart';
import 'package:transferr/screens/passengers/passengers_list_page.dart';
import 'package:transferr/screens/passengers/passenger_details_page.dart';
import 'package:transferr/screens/users/users_list_page.dart';
import 'package:transferr/screens/users/add_user_page.dart';
import 'package:transferr/screens/finance/finance_page.dart';
import 'package:transferr/screens/finance/excursion_finance_page.dart';

import 'config/theme/app_theme.dart';
import 'models/excursion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Providers Independentes
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ExcursionProvider()),
        ChangeNotifierProvider(create: (_) => PassengerProvider()),
        
        // 2. AuthProvider dependendo dos outros para limpeza (ProxyProvider)
        ChangeNotifierProxyProvider2<UserProvider, ExcursionProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, userProv, excProv, authProv) => authProv!..update(userProv, excProv),
        ),
      ],
      child: MaterialApp(
        title: 'Transferr',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: _buildRoutes(),
        onUnknownRoute: (settings) => MaterialPageRoute(builder: (context) => const AuthWrapper()),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const AuthWrapper(),
      '/register': (context) => const RegistrationPage(),
      '/home': (context) => const HomePage(),
      '/excursions': (context) => const ExcursionsPage(),
      '/add-excursion': (context) => const AddExcursionPage(),
      '/history': (context) => const HistoryPage(),
      '/my-company': (context) => const MyCompanyPage(),
      '/settings': (context) => const SettingsPage(),
      '/users': (context) => const UsersListPage(),
      '/add-user': (context) => const AddUserPage(),
      '/finance': (context) => const FinancePage(),
      
      '/excursion-dashboard': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is String ? ExcursionDashboardPage(excursionId: args) : _errorPage("ID inválido");
      },
      '/map-seats': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return ExcursionSeatMapPage(
            excursionId: args['excursionId'],
            totalSeats: args['totalSeats'] ?? 44,
            isSelectionMode: args['isSelectionMode'] ?? false,
            initialSelectedSeat: args['initialSelectedSeat'],
          );
        }
        return args is String ? ExcursionSeatMapPage(excursionId: args) : _errorPage("Parâmetros inválidos");
      },
      '/check-in': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is Map<String, dynamic> ? CheckInPage(excursionId: args['excursionId'], destinationName: args['destinationName'] ?? '') : _errorPage("Dados incompletos");
      },
      '/global-passengers': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is Map<String, dynamic> ? GlobalPassengersPage(excursionId: args['excursionId'], excursionPrice: args['excursionPrice']) : const GlobalPassengersPage();
      },
      '/passengers-list': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is String ? PassengersListPage(excursionId: args) : _errorPage("ID inválido");
      },
      '/add-passenger': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) return AddPassengerPage(excursionId: args['excursionId'], excursionPrice: args['excursionPrice'], passenger: args['passenger']);
        return args is String ? AddPassengerPage(excursionId: args) : _errorPage("Parâmetros insuficientes");
      },
      '/passenger-details': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is Map<String, dynamic> ? PassengerDetailsPage(passenger: args['passenger'], excursionId: args['excursionId']) : _errorPage("Dados inválidos");
      },
      '/excursion-finance': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return args is Excursion ? ExcursionFinancePage(excursion: args) : _errorPage("Dados inválidos");
      },
    };
  }

  Widget _errorPage(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erro")),
      body: Center(child: Text(message)),
    );
  }
}
