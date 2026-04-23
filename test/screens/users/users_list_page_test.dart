import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/screens/users/users_list_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockUserProvider mockUser;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockUser = MockUserProvider();

    // Configuração padrão de mocks para evitar erros de null
    when(() => mockUser.isLoading).thenReturn(false);
    when(() => mockUser.users).thenReturn([]);
    when(() => mockUser.usersCount).thenReturn(0);
    when(() => mockUser.pendingInvites).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider<UserProvider>.value(value: mockUser),
        ],
        child: const UsersListPage(),
      ),
    );
  }

  final tUser = User(
    id: 'u1',
    name: 'João Admin',
    email: 'admin@test.com',
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
    roles: {'emp_1': 'ADMIN'},
    profile: 'ADMIN',
    isActive: true,
    createdAt: DateTime.now(),
  );

  testWidgets('Deve mostrar loading indicator quando o provider estiver carregando', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockUser.isLoading).thenReturn(true);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Deve exibir a lista de usuários corretamente', (tester) async {
    final users = [
      tUser,
      tUser.copyWith(id: 'u2', name: 'Maria Agente', profile: 'AGENTE', roles: {'emp_1': 'AGENTE'}),
    ];

    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockUser.users).thenReturn(users);
    when(() => mockUser.usersCount).thenReturn(2);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('João Admin'), findsOneWidget);
    expect(find.text('Maria Agente'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('AGENTE'), findsOneWidget);
  });

  testWidgets('Deve mostrar badge de notificações se houver convites', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockUser.pendingInvites).thenReturn([{'id': 'inv1', 'fromCompanyName': 'Agência Parceira'}]);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    // O número '1' deve aparecer no badge
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Deve disparar busca ao digitar no campo de pesquisa', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);
    when(() => mockUser.searchUsers(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), 'Marcos');
    await tester.pump();

    verify(() => mockUser.searchUsers('Marcos')).called(1);
  });

  testWidgets('Deve exibir Empty State quando não houver usuários', (tester) async {
    when(() => mockAuth.currentUser).thenReturn(tUser);
    when(() => mockUser.users).thenReturn([]);
    when(() => mockUser.initCompanyStream(any())).thenReturn(null);
    when(() => mockUser.initInviteStream(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Nenhum operador encontrado.'), findsOneWidget);
    expect(find.byIcon(Icons.group_off), findsOneWidget);
  });
}
