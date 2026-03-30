import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/screens/register/registration_page.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
    when(() => mockAuth.isLoading).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuth,
      child: const MaterialApp(
        home: RegistrationPage(),
      ),
    );
  }

  group('RegistrationPage Flow Tests', () {
    testWidgets('Deve iniciar no Passo 1 e exibir campos básicos', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 3'), findsOneWidget);
      expect(find.text('PRÓXIMO'), findsOneWidget);
      expect(find.text('Dono de Agência (Organizador)'), findsOneWidget);
    });

    testWidgets('Não deve avançar para o Passo 2 se os campos estiverem vazios', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('PRÓXIMO'));
      await tester.pumpAndSettle(); 

      expect(find.text('Passo 1 de 3'), findsOneWidget);
      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('Deve avançar para o Passo 2 após preencher dados válidos no Passo 1', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // 1. Preenche Nome da Empresa (Campo 0)
      await tester.enterText(fields.at(0), 'Minha Agencia');
      
      // 2. Clica no botão de CNPJ para mudar o label/máscara
      await tester.tap(find.text('CNPJ'));
      await tester.pumpAndSettle();

      // 3. Preenche CNPJ (Campo 1)
      await tester.enterText(fields.at(1), '12.345.678/0001-99');
      
      // 4. Preenche Nome (Campo 2)
      await tester.enterText(fields.at(2), 'João Administrador');
      
      // 5. Preenche WhatsApp (Campo 3)
      await tester.enterText(fields.at(3), '(11) 99999-9999');

      await tester.pump();

      // Clica em PRÓXIMO
      await tester.tap(find.text('PRÓXIMO'));
      await tester.pumpAndSettle(); 

      // ASSERT: Agora devemos estar no Passo 2
      expect(find.text('Passo 2 de 3'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(1)); // Campos do Passo 2 (Endereço)
    });
  });
}
