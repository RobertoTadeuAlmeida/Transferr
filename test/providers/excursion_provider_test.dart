import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/models/enums.dart';
import 'package:transferr/models/expense.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/services/excursion_service.dart';

class MockExcursionService extends Mock implements ExcursionService {}
class FakeExcursion extends Fake implements Excursion {}
class FakeExpense extends Fake implements Expense {}

void main() {
  late ExcursionProvider excursionProvider;
  late MockExcursionService mockService;

  setUpAll(() {
    registerFallbackValue(FakeExcursion());
    registerFallbackValue(FakeExpense());
  });

  setUp(() {
    mockService = MockExcursionService();
    excursionProvider = ExcursionProvider(mockService);
  });

  final tExcursion = Excursion(
    id: '1', name: 'Ativa 1', idMainDestination: 'D1', startDate: DateTime.now(),
    returnDate: DateTime.now(), basePrice: 100, totalSeats: 10, slug: 'ativa-1',
    idResponsible: 'R1', empresa: 'comp_1', status: ExcursionStatus.programada,
  );

  group('ExcursionProvider - TDD de Integridade', () {
    test('addExcursion deve lançar erro se não houver ID de empresa', () async {
      final invalidEx = tExcursion.copyWith(empresa: '');
      
      expect(
        () => excursionProvider.addExcursion(invalidEx, ''),
        throwsA(isA<Exception>()),
      );
    });

    test('addExpense deve gerenciar corretamente o estado de loading', () async {
      when(() => mockService.addExpense(any(), any())).thenAnswer((_) async => {});

      final future = excursionProvider.addExpense(
        excursionId: 'ex1',
        description: 'Gasolina',
        value: 100.0,
        category: 'Transporte',
      );

      // Agora o Provider original foi endireitado para setar loading
      expect(excursionProvider.isLoading, isTrue);
      
      await future;
      expect(excursionProvider.isLoading, isFalse);
    });

    test('watchExpenses deve retornar a stream do service sem alterações', () {
      final expenses = [Expense(id: 'e1', description: 'G', value: 10, category: 'T', date: DateTime.now())];
      when(() => mockService.watchExpenses(any())).thenAnswer((_) => Stream.value(expenses));

      final stream = excursionProvider.watchExpenses('ex1');

      expect(stream, emits(expenses));
    });

    test('deleteExpense deve disparar erro caso o service falhe', () async {
      when(() => mockService.deleteExpense(any(), any())).thenThrow(Exception('Erro no Banco'));

      expect(
        () => excursionProvider.deleteExpense('ex1', 'exp1'),
        throwsA(isA<Exception>()),
      );
      
      expect(excursionProvider.isLoading, isFalse);
    });
  });
}
