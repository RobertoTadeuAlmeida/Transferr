import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/widgets/app_drawer.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
  });

  // Helper para criar o widget com o provider mockado
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuth,
        child: const Scaffold(drawer: AppDrawer()),
      ),
    );
  }

  final tUser = User(
    id: 'u1',
    name: 'João Teste',
    email: 'joao@test.com',
    phone: '11999999999',
    document: '123',
    birthDate: DateTime(1990, 1, 1),
    zipCode: '01001000',
    address: 'Rua A',
    number: '1',
    neighborhood: 'Centro',
    city: 'SP',
    state: 'SP',
    company: 'emp_1',
    companies: ['emp_1'],
    roles: {'emp_1': 'AGENTE'},
    profile: 'AGENTE',
    isActive: true,
    createdAt: DateTime.now(),
  );

  testWidgets('Agente NÃO deve ver itens de gestão de equipe', (WidgetTester tester) async {
    // Configura o mock para um Agente
    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockAuth.isAdmin).thenReturn(false);
    when(() => mockAuth.isAuthenticated).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    
    // Abre o drawer
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verifica se os itens básicos aparecem
    expect(find.text('Minhas Excursões'), findsOneWidget);
    
    // Verifica se os itens de admin NÃO aparecem
    expect(find.text('Gestão de Equipe'), findsNothing);
    expect(find.text('Financeiro Geral'), findsNothing);
  });

  testWidgets('Admin DEVE ver itens de gestão de equipe', (WidgetTester tester) async {
    // Configura o mock para um Admin
    final adminUser = tUser.copyWith(profile: 'ADMIN', roles: {'emp_1': 'ADMIN'});
    when(() => mockAuth.currentUser).thenReturn(adminUser);
    when(() => mockAuth.isAdmin).thenReturn(true);
    when(() => mockAuth.isAuthenticated).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    
    // Abre o drawer
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verifica se os itens de admin APARECEM
    expect(find.text('Gestão de Equipe'), findsOneWidget);
    expect(find.text('Minha Empresa'), findsOneWidget);
    expect(find.text('Financeiro Geral'), findsOneWidget);
  });
}
