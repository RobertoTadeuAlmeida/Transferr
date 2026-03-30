import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/providers/passenger_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/services/passenger_service.dart';

class MockPassengerService extends Mock implements PassengerService {}
class MockExcursionProvider extends Mock implements ExcursionProvider {}
class MockBuildContext extends Mock implements BuildContext {}
class FakePassenger extends Fake implements Passenger {}

void main() {
  late PassengerProvider passengerProvider;
  late MockPassengerService mockService;
  late MockBuildContext mockContext;
  late MockExcursionProvider mockExcursionProvider;

  setUpAll(() {
    registerFallbackValue(FakePassenger());
  });

  setUp(() {
    mockService = MockPassengerService();
    mockContext = MockBuildContext();
    mockExcursionProvider = MockExcursionProvider();
    passengerProvider = PassengerProvider(mockService);

    // FIX: Configurar o mock do BuildContext para não retornar Null em 'mounted'
    when(() => mockContext.mounted).thenReturn(true);
    
    // Como o Provider usa context.read<ExcursionProvider>(), 
    // em testes unitários simples, vamos apenas garantir que o mounted seja true.
    // O erro de Null no read é esperado se não mockarmos o Provider dentro do contexto,
    // então vamos envolver as chamadas que usam context em blocos try/catch ou mockar o read.
  });

  final tPassenger = Passenger(
    id: 'p1',
    empresa: 'comp1',
    name: 'João',
    document: '123',
    phone: '999',
    birthDate: DateTime(2000, 1, 1),
  );

  group('PassengerProvider Tests', () {
    test('initial state should be clean', () {
      expect(passengerProvider.isLoading, isFalse);
      expect(passengerProvider.errorMessage, isNull);
    });

    test('savePassenger should handle success', () async {
      when(() => mockService.savePassenger(
            passenger: any(named: 'passenger'),
            excursionId: any(named: 'excursionId'),
            depositValue: any(named: 'depositValue'),
          )).thenAnswer((_) async => {});
      
      // Como o código faz context.read<ExcursionProvider>(), vamos mockar o mounted como false
      // para este teste específico para evitar que ele tente ler o Provider do contexto inexistente.
      when(() => mockContext.mounted).thenReturn(false);

      final result = await passengerProvider.savePassenger(
        context: mockContext,
        passenger: tPassenger,
        excursionId: 'ex1',
        depositValue: 50.0,
      );

      expect(result, isTrue);
      expect(passengerProvider.isLoading, isFalse);
      verify(() => mockService.savePassenger(
            passenger: any(named: 'passenger'),
            excursionId: 'ex1',
            depositValue: 50.0,
          )).called(1);
    });

    test('should set errorMessage when service fails', () async {
      when(() => mockService.deletePassenger(any()))
          .thenThrow(Exception('Erro ao deletar'));

      try {
        await passengerProvider.deletePassenger('p1');
      } catch (_) {}

      expect(passengerProvider.errorMessage, contains('Erro ao deletar'));
      expect(passengerProvider.isLoading, isFalse);
    });

    test('settleFullPayment should set loading and call service', () async {
      when(() => mockService.settleFullPayment(
        passengerId: any(named: 'passengerId'),
        excursionId: any(named: 'excursionId'),
        fullValue: any(named: 'fullValue'),
      )).thenAnswer((_) async => {});

      // Mockando mounted como false para evitar o context.read
      when(() => mockContext.mounted).thenReturn(false);

      final future = passengerProvider.settleFullPayment(
        context: mockContext,
        passengerId: 'p1',
        excursionId: 'ex1',
        fullValue: 200.0,
      );

      expect(passengerProvider.isLoading, isTrue);
      await future;
      expect(passengerProvider.isLoading, isFalse);
      verify(() => mockService.settleFullPayment(
        passengerId: 'p1',
        excursionId: 'ex1',
        fullValue: 200.0,
      )).called(1);
    });
  });
}
