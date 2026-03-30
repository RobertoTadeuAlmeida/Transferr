import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/screens/settings/my_company_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockUserProvider extends Mock implements UserProvider {}
class MockExcursionProvider extends Mock implements ExcursionProvider {}

void main() {
  late MockAuthProvider mockAuth;
  late MockUserProvider mockUserProv;
  late MockExcursionProvider mockExcursionProv;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockUserProv = MockUserProvider();
    mockExcursionProv = MockExcursionProvider();

    final tUser = User(
      id: 'u1',
      name: 'João Silva',
      email: 'joao@test.com',
      company: 'comp_1',
      companyName: 'Empresa Alpha',
      companies: ['comp_1', 'comp_2'],
      roles: {'comp_1': 'ADMIN', 'comp_2': 'AGENTE'},
      phone: '', document: '', birthDate: DateTime.now(),
      zipCode: '', address: '', number: '', neighborhood: '',
      city: '', state: '', createdAt: DateTime.now(),
    );

    when(() => mockAuth.currentUser).thenReturn(tUser);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<UserProvider>.value(value: mockUserProv),
        ChangeNotifierProvider<ExcursionProvider>.value(value: mockExcursionProv),
      ],
      child: const MaterialApp(
        home: MyCompanyPage(),
      ),
    );
  }

  group('MyCompanyPage Widget Tests', () {
    testWidgets('Deve exibir o nome da empresa ativa no header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Empresa Alpha'), findsOneWidget);
    });

    testWidgets('Deve listar as IDs das empresas vinculadas', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // comp_1 aparece no header e na lista, então usamos findsAtLeast
      expect(find.text('ID: comp_1'), findsAtLeast(1));
      // comp_2 aparece apenas na lista
      expect(find.text('ID: comp_2'), findsOneWidget);
    });

    testWidgets('Deve disparar o switchCompany ao clicar em uma empresa diferente', (WidgetTester tester) async {
      when(() => mockAuth.switchCompany(any())).thenAnswer((_) async => {});
      when(() => mockExcursionProv.listenToExcursions(any())).thenReturn(null);
      when(() => mockUserProv.initCompanyStream(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      // Clica especificamente no tile que NÃO é o atual
      final tileToClick = find.text('Mudar para esta empresa');
      await tester.tap(tileToClick);
      await tester.pump(); 

      verify(() => mockAuth.switchCompany('comp_2')).called(1);
    });
  });
}
