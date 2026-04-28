import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/demo_config.dart';
import 'providers/demo_mode_provider.dart';
import 'services/demo_user_service.dart';
import 'services/demo_passenger_service.dart';
import 'ui/login/demo_toggle_button.dart';

class DemoApp extends StatelessWidget {
  final DemoUserService _userService = DemoUserService();
  final DemoPassengerService _passengerService = DemoPassengerService();

  DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoModeProvider()),
      ],
      child: MaterialApp(
        title: 'Transferr - Demo',
        debugShowCheckedModeBanner: false,
        home: DemoHome(userService: _userService, passengerService: _passengerService),
      ),
    );
  }
}

class DemoHome extends StatelessWidget {
  final DemoUserService userService;
  final DemoPassengerService passengerService;
  const DemoHome({super.key, required this.userService, required this.passengerService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferr - Modo Demo'), actions: const [DemoToggleButton()]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Usuários (demo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List>(
                stream: userService.getUsersStream('c_demo'),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snap.data!;
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final user = list[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('Passageiros (demo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List>(
                stream: passengerService.getGlobalPassengersStream('c_demo'),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snap.data!;
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final p = list[index];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.document),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
