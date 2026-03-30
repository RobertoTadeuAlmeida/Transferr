import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/models/enums.dart';
import 'package:transferr/repositories/excursion_repository.dart';
import 'package:transferr/repositories/passenger_repository.dart';
import 'package:transferr/services/excursion_service.dart';

class MockExcursionRepository extends Mock implements ExcursionRepository {}
class MockPassengerRepository extends Mock implements PassengerRepository {}
class FakeExcursion extends Fake implements Excursion {}

void main() {
  late ExcursionService excursionService;
  late MockExcursionRepository mockExcursionRepo;
  late MockPassengerRepository mockPassengerRepo;

  setUpAll(() {
    registerFallbackValue(FakeExcursion());
  });

  setUp(() {
    mockExcursionRepo = MockExcursionRepository();
    mockPassengerRepo = MockPassengerRepository();
    
    // Agora o Service só recebe os Repositories (Arquitetura Limpa)
    excursionService = ExcursionService(mockExcursionRepo, mockPassengerRepo);
  });

  final tExcursion = Excursion(
    id: 'ex_123',
    name: '  Viagem Teste  ',
    idMainDestination: 'dest_1',
    startDate: DateTime.now(),
    returnDate: DateTime.now().add(const Duration(days: 2)),
    basePrice: 100.0,
    totalSeats: 40,
    slug: 'viagem-teste',
    idResponsible: 'user_1',
    empresa: 'comp_1',
    status: ExcursionStatus.programada,
  );

  group('ExcursionService - createExcursion', () {
    test('should trim name and call repository add', () async {
      when(() => mockExcursionRepo.add(any())).thenAnswer((_) async => {});

      await excursionService.createExcursion(tExcursion);

      final captured = verify(() => mockExcursionRepo.add(captureAny())).captured.first as Excursion;
      expect(captured.name, 'Viagem Teste');
    });
  });

  group('ExcursionService - Status Management', () {
    test('startExcursion should throw error if excursion is CANCELADA', () async {
      // ARRANGE
      final canceledEx = tExcursion.copyWith(status: ExcursionStatus.cancelada);
      when(() => mockExcursionRepo.getExcursionById(any())).thenAnswer((_) async => canceledEx);

      // ACT & ASSERT
      expect(
        () => excursionService.startExcursion('ex_123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Não é possível iniciar uma viagem finalizada ou cancelada'))),
      );
    });

    test('startExcursion should call update if status is valid', () async {
      // ARRANGE
      when(() => mockExcursionRepo.getExcursionById(any())).thenAnswer((_) async => tExcursion);
      when(() => mockExcursionRepo.update(any(), any())).thenAnswer((_) async => {});

      // ACT
      await excursionService.startExcursion('ex_123');

      // ASSERT
      verify(() => mockExcursionRepo.update('ex_123', any(that: containsPair('status', 'EM_ANDAMENTO')))).called(1);
    });
  });

  group('ExcursionService - finalizeExcursion', () {
    test('should identify boarded passengers and call repository batch', () async {
      // ARRANGE: Mock de vagas (uma embarcou, outra não)
      final mockSnap = MockQuerySnapshot();
      final doc1 = MockQueryDocSnap(id: 'p1', data: {'statusEmbarque': 'EMBARCOU'});
      final doc2 = MockQueryDocSnap(id: 'p2', data: {'statusEmbarque': 'AGUARDANDO'});
      
      when(() => mockSnap.docs).thenReturn([doc1, doc2]);
      when(() => mockExcursionRepo.getVacancies(any())).thenAnswer((_) async => mockSnap);
      when(() => mockExcursionRepo.finalizeExcursionBatch(
        excursionId: any(named: 'excursionId'),
        passengerUpdates: any(named: 'passengerUpdates'),
        totalEfetivo: any(named: 'totalEfetivo'),
      )).thenAnswer((_) async => {});

      // ACT
      await excursionService.finalizeExcursion('ex_123');

      // ASSERT
      final capturedUpdates = verify(() => mockExcursionRepo.finalizeExcursionBatch(
        excursionId: 'ex_123',
        passengerUpdates: captureAny(named: 'passengerUpdates'),
        totalEfetivo: 1, // Apenas p1 embarcou
      )).captured.first as List<Map<String, dynamic>>;

      expect(capturedUpdates.length, 2);
      // Verifica se o p1 tem o incremento de viagens (pois embarcou)
      expect(capturedUpdates.firstWhere((u) => u['id'] == 'p1')['data'], containsPair('totalViagens', isA<FieldValue>()));
      // Verifica se o p2 NÃO tem incremento
      expect(capturedUpdates.firstWhere((u) => u['id'] == 'p2')['data'].containsKey('totalViagens'), isFalse);
    });
  });
}

// Mocks auxiliares para o Firestore
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocSnap extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  MockQueryDocSnap({required String id, required Map<String, dynamic> data}) : _id = id, _data = data;
  @override String get id => _id;
  @override Map<String, dynamic> data() => _data;
}
