import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/screens/login/pending_company_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockUserProvider extends Mock implements UserProvider {}
class FakeUser extends Fake implements User {}

void main() {
  late MockAuthProvider mockAuth;
  late MockUserProvider mockUser;

  final tUser = User(
    id: 'u123',
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
    company: '',
    companies: [],
    roles: {},
    profile: 'AGENTE',
    isActive: true,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    // Necessário para usar any() com o tipo User no Mocktail
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockAuth = MockAuthProvider();
    mockUser = MockUserProvider();

    when(() => mockUser.pendingInvites).thenReturn([]);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(tUser);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider<UserProvider>.value(value: mockUser),
        ],
        child: const PendingCompanyPage(),
      ),
    );
  }

  testWidgets('Deve exibir o nome do usuário e estados vazios inicialmente', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.textContaining('Olá, João!'), findsOneWidget);
    expect(find.text('Nenhum convite recebido.'), findsOneWidget);
  });

  testWidgets('Deve listar convites e permitir aceitar', (tester) async {
    final invite = {
      'id': 'inv1',
      'fromCompanyName': 'Agência XYZ',
      'fromCompanyId': 'comp_xyz'
    };
    
    when(() => mockUser.pendingInvites).thenReturn([invite]);
    when(() => mockUser.respondToInvite(
      inviteId: any(named: 'inviteId'),
      status: any(named: 'status'),
      currentUser: any(named: 'currentUser'),
      companyId: any(named: 'companyId'),
    )).thenAnswer((_) async => {});
    when(() => mockAuth.refreshUser()).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Agência XYZ'), findsOneWidget);
    
    await tester.tap(find.text('ACEITAR'));
    await tester.pumpAndSettle();

    verify(() => mockUser.respondToInvite(
      inviteId: 'inv1',
      status: 'ACEITO',
      currentUser: any(named: 'currentUser'),
      companyId: 'comp_xyz',
    )).called(1);
  });

  testWidgets('Deve validar nome da empresa ao criar organização', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Scroll até o botão se necessário e clica
    final buttonFinder = find.text('CRIAR MINHA ORGANIZAÇÃO');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Por favor, informe o nome da sua agência.'), findsOneWidget);
  });

  testWidgets('Deve chamar createCompany com sucesso ao preencher nome', (tester) async {
    when(() => mockAuth.createCompany(any())).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());

    final textFieldFinder = find.byType(TextField);
    await tester.ensureVisible(textFieldFinder);
    await tester.enterText(textFieldFinder, 'Minha Nova Agência');
    await tester.pump();

    final buttonFinder = find.text('CRIAR MINHA ORGANIZAÇÃO');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump();

    verify(() => mockAuth.createCompany('Minha Nova Agência')).called(1);
  });
}
