import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/firebase_options.dart';
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

  final Map<String, dynamic> firebaseConfig = jsonDecode(firebaseConfigString);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    if (initialAuthToken.isNotEmpty) {
      await FirebaseAuth.instance.signInWithCustomToken(initialAuthToken);
      print(
        'Autenticado com token personalizado: ${FirebaseAuth.instance.currentUser?.uid}',
      );
    } else {
      await FirebaseAuth.instance.signInAnonymously();
      print(
        'Autenticado anonimamente: ${FirebaseAuth.instance.currentUser?.uid}',
      );
    }
  } catch (e) {
    print("Erro na autenticação Firebase: $e");
  }

  // Envolve o aplicativo com o ChangeNotifierProvider para o ExcursionProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExcursionProvider()),
        // Você poderia adicionar outros providers aqui, como ClientProvider, etc.
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
      title: 'App de Gerenciamento de Excursões',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A), // AppBar transparente/escura
          foregroundColor: Colors.white,
          elevation: 0, // Sem sombra na AppBar
          iconTheme: IconThemeData(color: Colors.white), // Ícones brancos
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1A1A1A), // Fundo do Drawer escuro
        ),
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
            backgroundColor: const Color(0xFFF97316), // Cor de fundo dos botões
            foregroundColor: Colors.white, // Cor do texto dos botões
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
        '/': (context) => const HomePage(),
        // TODO: Atualizar as outras telas para usar Provider
        '/excursion_details': (context) => ExcursionDetailsPage(
          excursion: ModalRoute.of(context)!.settings.arguments as Excursion,
        ),
        '/clients': (context) => const ClientsListPage(),
        '/client_details': (context) => ClientDetailsPage(
          client: ModalRoute.of(context)!.settings.arguments as Client,
        ),
        '/finance': (context) => const FinancePage(),
      },
    );
  }
}

void addExcursionToFirestore() async {
  // Objeto de dados (semelhante a um JSON) para a nova excursão.
  // Em Dart, usamos um Map<String, dynamic>.
  final Map<String, dynamic> newExcursionData = {
    'name': 'Trilha da Cachoeira',
    'date': '2025-10-26',
    'price': 150.00,
    'status': 'Agendada',
    'grossRevenue': 0.0,
    'netRevenue': 0.0,
    'totalClientsConfirmed': 0,
  };

  try {
    // Obter a instância do Firestore.
    final db = FirebaseFirestore.instance;

    // Adicionar o novo documento à coleção 'excursions'.
    // O Firestore gerará um ID único para este novo documento.
    await db.collection('excursions').add(newExcursionData);

    print(
      'Excursão "Trilha da Cachoeira" adicionada com sucesso ao Firestore!',
    );
  } catch (e) {
    print('Erro ao adicionar excursão ao Firestore: $e');
  }
}
