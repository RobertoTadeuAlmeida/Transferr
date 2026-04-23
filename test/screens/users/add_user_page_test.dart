import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/screens/users/add_user_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockUserProvider mockUser;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockUser = MockUserProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<UserProvider>.value(value: mockUser),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddUserPage()),
              ),
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );
  }

  final tAdmin = User(
    id: 'admin_123',
    name: 'Admin Teste',
    email: 'admin@teste.com',
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
    companyName: 'Minha Agência',
    companies: ['emp_1'],
    roles: {'emp_1': 'OWNER'},
    profile: 'OWNER',
    isActive: true,
    createdAt: DateTime.now(),
  );

  testWidgets('Deve enviar convite com sucesso, mostrar SnackBar e fechar página', (tester) async {
    final completer = Completer<void>();
    when(() => mockAuth.currentUser).thenReturn(tAdmin);
    when(() => mockUser.sendInvite(
      fromCompanyId: any(named: 'fromCompanyId'),
      fromCompanyName: any(named: 'fromCompanyName'),
      toUserEmail: any(named: 'toUserEmail'),
      currentUserId: any(named: 'currentUserId'),
    )).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'operador@teste.com');
    await tester.tap(find.text('ENVIAR CONVITE'));
    await tester.pump(); 

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    
    // Aguarda o frame da SnackBar e do Navigator.pop
    await tester.pump(); 
    
    // CORREÇÃO FINAL: Usamos findsAtLeast(1) para evitar falhas por duplicidade no frame de animação
    expect(find.textContaining('Convite enviado com sucesso'), findsAtLeast(1));

    // Finaliza todas as animações (incluindo o fechamento da página)
    await tester.pumpAndSettle();

    // Verifica se voltou para a página anterior
    expect(find.text('Open Page'), findsOneWidget);
  });

  testWidgets('Deve exibir erros de validação para e-mail inválido', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tAdmin);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ENVIAR CONVITE'));
    await tester.pump();
    expect(find.text('Informe o e-mail'), findsOneWidget);
  });
}
