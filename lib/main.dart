import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/firebase_options.dart';
import 'package:transferr/providers/client_provider.dart';
import 'package:transferr/screens/auth_wrapper.dart';
import 'package:transferr/screens/excursion_dashboard_page.dart';
import 'dart:convert';
import 'models/excursion.dart';
import 'models/client.dart';
import 'providers/excursion_provider.dart';
import 'screens/home_page.dart';
import 'screens/excursions/excursion_details_page.dart';
import 'screens/clients_list_page.dart';
import 'screens/client_details_page.dart';
import 'screens/finance_page.dart';

final String appId = const String.fromEnvironment(
  '1:893379584608:android:25ef44854c6cbde0071905',
  defaultValue: 'transferr-gestao-dev',
);
final String firebaseConfigString = const String.fromEnvironment(
  'FIREBASE_CONFIG',
  defaultValue: '{}',
);
final String initialAuthToken = const String.fromEnvironment(
  'INITIAL_AUTH_TOKEN',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExcursionProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1A1A1A)),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
          secondary: Color(0xFFF97316),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF97316),
            // Cor de fundo dos botões
            foregroundColor: Colors.white,
            // Cor do texto dos botões
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                10.0,
              ), // Cantos arredondados para botões
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF97316), // Cor do FAB
          foregroundColor: Colors.white, // Cor do ícone/texto do FAB
        ),
        cardTheme: CardThemeData(
          margin: const EdgeInsets.all(8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16.0,
            ), // Cantos arredondados mais proeminentes
          ),
          color: const Color(0xFFF97316), // Cor dos cartões
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/excursion_details': (context) {
          final String excursionId =
              ModalRoute.of(context)!.settings.arguments as String;
          return ExcursionDashboardPage(excursionId: excursionId);
        },
        '/clients': (context) => const ClientsListPage(),
        '/client_details': (context) {
          final String clientId =
              ModalRoute.of(context)!.settings.arguments as String;
          return ClientDetailsPage(clientId: clientId);
        },

        '/finance': (context) => const FinancePage(),
      },
    );
  }
}
