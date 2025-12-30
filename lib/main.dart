import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:transferr/firebase_options.dart';
import 'package:transferr/providers/client_provider.dart';
import 'package:transferr/screens/clients/add_edit_client_page.dart';
import 'package:transferr/screens/auth_wrapper.dart';
import 'package:transferr/screens/clients/clients_list_page.dart';
import 'package:transferr/screens/excursions/excursion_dashboard_page.dart';
import 'package:transferr/screens/excursions/excursions_page.dart';
import 'package:transferr/screens/settings_page.dart';
import 'config/theme/app_theme.dart';
import 'providers/excursion_provider.dart';
import 'screens/clients/client_details_page.dart';
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
        ChangeNotifierProxyProvider<ExcursionProvider, ClientProvider>(
          create: (context) => ClientProvider(),
          update: (context, excursionProvider, previousClientProvider) =>
              ClientProvider(excursionProvider: excursionProvider),
        ),
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
      debugShowCheckedModeBanner: false, // Adicionado para limpar a UI

      // 2. APLIQUE O TEMA DO ARQUIVO EXTERNO
      theme: AppTheme.darkTheme,

      // 3. O gerenciamento de rotas permanece o mesmo
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/excursions': (context) => const ExcursionsPage(),
        '/excursion_details': (context) {
          final String excursionId =
          ModalRoute.of(context)!.settings.arguments as String;
          return ExcursionDashboardPage(excursionId: excursionId);
        },
        '/clients': (context) => const ClientsListPage(),
        '/add_edit_client': (context) => const AddEditClientPage(),
        '/client_details': (context) {
          final String clientId =
          ModalRoute.of(context)!.settings.arguments as String;
          return ClientDetailsPage(clientId: clientId);
        },
        '/settings': (context) => const SettingsPage(),
        '/finance': (context) => const FinancePage(),
      },
    );
  }
}
