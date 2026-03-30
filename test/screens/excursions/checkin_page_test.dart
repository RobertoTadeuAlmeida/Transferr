import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/models/enums.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/screens/excursions/checkin_page.dart';

class MockExcursionProvider extends Mock implements ExcursionProvider {}
class MockPassengerProvider extends Mock implements PassengerProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockExcursionProvider mockExcursionProv;
  late MockPassengerProvider mockPassengerProv;
  late MockAuthProvider mockAuthProv;

  setUpAll(() {
    registerFallbackValue(BoardingStatus.aguardando);
    registerFallbackValue(MockBuildContext());
  });

  setUp(() {
    mockExcursionProv = MockExcursionProvider();
    mockPassengerProv = MockPassengerProvider();
    mockAuthProv = MockAuthProvider();

    final tExcursion = Excursion(
      id: 'ex_1',
      name: 'Viagem Teste',
      idMainDestination: 'Destino',
      startDate: DateTime.now(),
      returnDate: DateTime.now(),
      basePrice: 100,
      totalSeats: 40,
      slug: 'slug',
      idResponsible: 'r1',
      empresa: 'comp_1',
      status: ExcursionStatus.programada,
    );

    final tUser = User(
      id: 'u1',
      name: 'User',
      email: 'u@u.com',
      company: 'comp_1',
      companyName: 'Empresa',
      companies: ['comp_1'],
      roles: {'comp_1': 'ADMIN'},
      phone: '', document: '', birthDate: DateTime.now(),
      zipCode: '', address: '', number: '', neighborhood: '',
      city: '', state: '', createdAt: DateTime.now(),
    );

    final tPassenger = Passenger(
      id: 'p1',
      empresa: 'comp_1',
      name: 'Passageiro 1',
      document: '123',
      phone: '456',
      birthDate: DateTime.now(),
      statusEmbarque: BoardingStatus.aguardando,
      seatNumber: '01',
    );

    when(() => mockExcursionProv.getExcursionById('ex_1')).thenReturn(tExcursion);
    when(() => mockExcursionProv.isLoading).thenReturn(false);
    
    when(() => mockPassengerProv.watchPassengers(any(), any())).thenAnswer((_) => Stream.value([tPassenger]));
    when(() => mockPassengerProv.isLoading).thenReturn(false);
    
    when(() => mockAuthProv.currentUser).thenReturn(tUser);
  });

  Widget createWidgetUnderTest({bool isStarting = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExcursionProvider>.value(value: mockExcursionProv),
        ChangeNotifierProvider<PassengerProvider>.value(value: mockPassengerProv),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProv),
      ],
      child: MaterialApp(
        home: CheckInPage(
          excursionId: 'ex_1', 
          destinationName: 'Destino',
          isStarting: isStarting,
        ),
      ),
    );
  }

  group('CheckInPage TDD Tests', () {
    testWidgets('Deve exibir o botão de INICIAR VIAGEM no modo isStarting', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isStarting: true));
      await tester.pumpAndSettle();

      // O texto correto no botão é este:
      expect(find.text('TUDO PRONTO! INICIAR VIAGEM'), findsOneWidget);
    });

    testWidgets('Deve chamar startExcursion ao clicar no botão de início', (tester) async {
      // No modo isStarting, o botão só habilita se todos estiverem validados.
      // Vamos simular um passageiro já EMBARCADO para que o contador processe (processados == total)
      final boardedPassenger = Passenger(
        id: 'p1', empresa: 'comp_1', name: 'P1', document: '1', phone: '1', 
        birthDate: DateTime.now(), statusEmbarque: BoardingStatus.embarcou
      );
      
      when(() => mockPassengerProv.watchPassengers(any(), any())).thenAnswer((_) => Stream.value([boardedPassenger]));
      when(() => mockExcursionProv.startExcursion('ex_1')).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest(isStarting: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TUDO PRONTO! INICIAR VIAGEM'));
      await tester.pump();

      verify(() => mockExcursionProv.startExcursion('ex_1')).called(1);
    });

    testWidgets('Deve exibir o status do passageiro e permitir troca de embarque', (tester) async {
      when(() => mockPassengerProv.updateOperationalData(
        context: any(named: 'context'),
        excursionId: any(named: 'excursionId'),
        passengerId: any(named: 'passengerId'),
        status: any(named: 'status'),
      )).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest(isStarting: true));
      await tester.pumpAndSettle();

      expect(find.text('Passageiro 1'), findsOneWidget);

      // Clica no ícone de check (embarque)
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pump();

      verify(() => mockPassengerProv.updateOperationalData(
        context: any(named: 'context'),
        excursionId: 'ex_1',
        passengerId: 'p1',
        status: BoardingStatus.embarcou,
      )).called(1);
    });
  });
}
