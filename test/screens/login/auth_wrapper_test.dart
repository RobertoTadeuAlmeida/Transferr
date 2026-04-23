import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/screens/home_page.dart';
import 'package:transferr/screens/login/auth_wrapper.dart';
import 'package:transferr/screens/login/login_page.dart';
import 'package:transferr/screens/login/pending_company_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockExcursionProvider extends Mock implements ExcursionProvider {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockExcursionProvider mockExcursion;
  late MockUserProvider mockUser;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockExcursion = MockExcursionProvider();
    mockUser = MockUserProvider();

    // Configurações padrão Auth
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.errorMessage).thenReturn(null);
    when(() => mockAuth.currentUser).thenReturn(null);

    // Configurações padrão para HomePage não quebrar
    when(() => mockExcursion.isLoading).thenReturn(false);
    when(() => mockExcursion.activeExcursions).thenReturn([]);
    when(() => mockExcursion.listenToExcursions(any())).thenReturn(null);
    
    when(() => mockUser.pendingInvites).thenReturn([]);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<ExcursionProvider>.value(value: mockExcursion),
        ChangeNotifierProvider<UserProvider>.value(value: mockUser),
      ],
      child: MaterialApp(
        // Adicionamos rotas básicas caso as telas usem Navigator.pushNamed
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Page')),
          '/home': (_) => const Scaffold(body: Text('Home Page')),
        },
        home: const AuthWrapper(),
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
    companyName: 'Minha Agência',
    companies: ['emp_1'],
    roles: {'emp_1': 'ADMIN'},
    profile: 'ADMIN',
    isActive: true,
    createdAt: DateTime.now(),
  );

  testWidgets('Deve mostrar loading quando authProvider.isLoading for true', (tester) async {
    when(() => mockAuth.isLoading).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sincronizando sua conta...'), findsOneWidget);
  });

  testWidgets('Deve mostrar LoginPage quando não houver usuário logado', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Deve mostrar HomePage quando usuário estiver logado e tiver empresa', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tUser);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Deve mostrar PendingCompanyPage quando usuário não tiver empresa vinculada', (tester) async {
    // IMPORTANTE: user.hasNoCompany retorna true se companies e company estiverem vazios
    final userSemEmpresa = tUser.copyWith(company: '', companies: []);
    when(() => mockAuth.currentUser).thenReturn(userSemEmpresa);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(PendingCompanyPage), findsOneWidget);
  });

  testWidgets('Deve mostrar tela de conta inativa quando isActive for false', (tester) async {
    final userInativo = tUser.copyWith(isActive: false);
    when(() => mockAuth.currentUser).thenReturn(userInativo);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Acesso Restrito'), findsOneWidget);
  });

  testWidgets('Deve mostrar tela de erro crítico quando houver mensagem de erro', (tester) async {
    when(() => mockAuth.errorMessage).thenReturn('Erro de Conexão');
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Ops! Algo deu errado'), findsOneWidget);
    expect(find.text('Erro de Conexão'), findsOneWidget);
  });
}
