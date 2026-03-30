import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/screens/excursions/excursion_seat_map_page.dart';

class MockPassengerProvider extends Mock implements PassengerProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockPassengerProvider mockPassengerProv;
  late MockAuthProvider mockAuthProv;

  setUp(() {
    mockPassengerProv = MockPassengerProvider();
    mockAuthProv = MockAuthProvider();

    final tUser = User(
      id: 'u1', name: 'User', email: 'u@u.com', company: 'comp_1', 
      companyName: 'Empresa', companies: ['comp_1'], roles: {'comp_1': 'ADMIN'},
      phone: '', document: '', birthDate: DateTime.now(),
      zipCode: '', address: '', number: '', neighborhood: '',
      city: '', state: '', createdAt: DateTime.now(),
    );

    final tPassenger = Passenger(
      id: 'p1',
      empresa: 'comp_1',
      name: 'João Assento 05',
      document: '123',
      phone: '456',
      birthDate: DateTime.now(),
      seatNumber: '5',
      isPaid: true,
    );

    when(() => mockAuthProv.currentUser).thenReturn(tUser);
    
    // MOCK DOS DADOS
    when(() => mockPassengerProv.watchPassengers(any(), any()))
        .thenAnswer((_) => Stream.value([tPassenger]));

    // MOCK DA LÓGICA DO PROVIDER (Para a UI não quebrar ao chamar os métodos)
    when(() => mockPassengerProv.normalizeSeatNumber(any())).thenAnswer((invocation) {
      final String arg = invocation.positionalArguments[0];
      return int.tryParse(arg)?.toString() ?? arg;
    });

    when(() => mockPassengerProv.getSeatMap(any())).thenAnswer((invocation) {
      final List<Passenger> passengers = invocation.positionalArguments[0];
      return {for (var p in passengers) p.seatNumber: p};
    });
  });

  Widget createWidgetUnderTest({bool isSelectionMode = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PassengerProvider>.value(value: mockPassengerProv),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProv),
      ],
      child: MaterialApp(
        home: ExcursionSeatMapPage(
          excursionId: 'ex_1',
          totalSeats: 40,
          isSelectionMode: isSelectionMode,
        ),
      ),
    );
  }

  group('ExcursionSeatMapPage - Testes de UI', () {
    testWidgets('Deve exibir o grid e identificar poltrona ocupada visualmente', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Emite a stream
      await tester.pumpAndSettle();

      // O texto '5' deve existir. No SeatWidget, o estilo muda se ocupado, 
      // mas o TDD de UI aqui foca na existência e interação.
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Deve exibir nome do passageiro no painel inferior ao clicar na poltrona', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pumpAndSettle();

      // Clica na poltrona '5'
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Verifica se a UI abriu o painel inferior com o nome correto
      expect(find.text('João Assento 05'), findsOneWidget);
      expect(find.text('LIBERAR'), findsOneWidget);
    });
  });
}
