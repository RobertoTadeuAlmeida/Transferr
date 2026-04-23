import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/screens/login/login_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
    when(() => mockAuth.isLoading).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        '/register': (context) => const Scaffold(body: Text('Register Page')),
      },
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuth,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('Deve exibir erros de validação se campos estiverem vazios', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Senha curta'), findsOneWidget);
  });

  testWidgets('Deve chamar authProvider.login com credenciais corretas ao clicar em ENTRAR', (tester) async {
    when(() => mockAuth.login(any(), any())).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextFormField).first, 'teste@email.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    verify(() => mockAuth.login('teste@email.com', '123456')).called(1);
  });

  testWidgets('Deve mostrar loading e desabilitar botão quando isLoading for true', (tester) async {
    when(() => mockAuth.isLoading).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    final loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(loginButton.onPressed, isNull);
  });

  testWidgets('Deve exibir SnackBar de erro se o login falhar', (tester) async {
    // Simulamos um erro genérico que cai no bloco 'catch (e)' da LoginPage
    when(() => mockAuth.login(any(), any())).thenThrow(Exception('Falha de conexão'));

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextFormField).first, 'erro@email.com');
    await tester.enterText(find.byType(TextFormField).last, '123456');

    await tester.tap(find.text('ENTRAR'));
    
    // pumpAndSettle aguarda todas as animações (incluindo a da SnackBar)
    await tester.pumpAndSettle();

    // Verificamos a mensagem de erro genérica que a LoginPage exibe para Exceptions comuns
    expect(
      find.descendant(
        of: find.byType(SnackBar), 
        matching: find.text('Erro inesperado. Verifique sua conexão.')
      ), 
      findsAtLeast(1)
    );
  });

  testWidgets('Deve navegar para tela de registro ao clicar em Cadastre sua Empresa', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Cadastre sua Empresa'));
    await tester.pumpAndSettle();

    expect(find.text('Register Page'), findsOneWidget);
  });
}
