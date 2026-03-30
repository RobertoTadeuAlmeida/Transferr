import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/repositories/passenger_repository.dart';
import 'package:transferr/services/passenger_service.dart';

class MockPassengerRepository extends Mock implements PassengerRepository {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class FakePassenger extends Fake implements Passenger {}

void main() {
  late PassengerService passengerService;
  late MockPassengerRepository mockRepo;

  setUpAll(() {
    // REGISTRO OBRIGATÓRIO PARA MOCKTAIL
    registerFallbackValue(FakePassenger());
  });

  setUp(() {
    mockRepo = MockPassengerRepository();
    passengerService = PassengerService(mockRepo);
  });

  final tPassenger = Passenger(
    id: 'p123',
    empresa: 'comp1',
    name: '  João Silva  ',
    document: '123',
    phone: '999',
    birthDate: DateTime(2000, 1, 1),
    seatNumber: ' 12A ',
  );

  group('PassengerService - savePassenger', () {
    test('should throw exception if name is empty', () async {
      final invalid = tPassenger.copyWith(name: '  ');
      expect(
        () => passengerService.savePassenger(passenger: invalid),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('nome do passageiro é obrigatório'))),
      );
    });

    test('should trim name and seat, then call repo.savePassenger when no excursion', () async {
      when(() => mockRepo.savePassenger(any())).thenAnswer((_) async => 'p123');

      await passengerService.savePassenger(passenger: tPassenger);

      final captured = verify(() => mockRepo.savePassenger(captureAny())).captured.first as Passenger;
      expect(captured.name, 'João Silva');
      expect(captured.seatNumber, '12A');
    });

    test('should check seat conflict and call transaction when excursion is provided', () async {
      const tExcursionId = 'ex1';
      final mockConflict = MockQuerySnapshot();
      when(() => mockConflict.docs).thenReturn([]); 
      when(() => mockRepo.findSeatConflict(tExcursionId, '12A')).thenAnswer((_) async => mockConflict);

      final mockVacancy = MockDocumentSnapshot();
      when(() => mockVacancy.exists).thenReturn(true);
      when(() => mockVacancy.data()).thenReturn({'saleValue': 150.0, 'isPaid': false});
      when(() => mockRepo.getVacancyDoc(tExcursionId, 'p123')).thenAnswer((_) async => mockVacancy);

      when(() => mockRepo.savePassenger(any())).thenAnswer((_) async => 'p123');
      when(() => mockRepo.runVacancyTransaction(
        excursionId: any(named: 'excursionId'),
        passengerId: any(named: 'passengerId'),
        isNew: any(named: 'isNew'),
        wasPaid: any(named: 'wasPaid'),
        isFullyPaid: any(named: 'isFullyPaid'),
        vacancyData: any(named: 'vacancyData'),
      )).thenAnswer((_) async => {});

      await passengerService.savePassenger(
        passenger: tPassenger,
        excursionId: tExcursionId,
        depositValue: 150.0,
      );

      verify(() => mockRepo.findSeatConflict(tExcursionId, '12A')).called(1);
      verify(() => mockRepo.runVacancyTransaction(
        excursionId: tExcursionId,
        passengerId: 'p123',
        isNew: false,
        wasPaid: false,
        isFullyPaid: true,
        vacancyData: any(named: 'vacancyData', that: containsPair('isPaid', true)),
      )).called(1);
    });
  });

  group('PassengerService - settleFullPayment', () {
    test('should call repository batch with correct values', () async {
      when(() => mockRepo.settleFullPaymentBatch(
        passengerId: any(named: 'passengerId'),
        excursionId: any(named: 'excursionId'),
        fullValue: any(named: 'fullValue'),
      )).thenAnswer((_) async => {});

      await passengerService.settleFullPayment(
        passengerId: 'p1',
        excursionId: 'ex1',
        fullValue: 200.0,
      );

      verify(() => mockRepo.settleFullPaymentBatch(
        passengerId: 'p1',
        excursionId: 'ex1',
        fullValue: 200.0,
      )).called(1);
    });
  });

  group('PassengerService - updateOperationalStatus', () {
    test('should update isPaid and incrementPaidCount when fully paid for the first time', () async {
      final mockVacancy = MockDocumentSnapshot();
      when(() => mockVacancy.exists).thenReturn(true);
      when(() => mockVacancy.data()).thenReturn({'saleValue': 100.0, 'isPaid': false});
      when(() => mockRepo.getVacancyDoc('ex1', 'p1')).thenAnswer((_) async => mockVacancy);
      
      when(() => mockRepo.updateOperationalBatch(
        passengerId: any(named: 'passengerId'),
        excursionId: any(named: 'excursionId'),
        updates: any(named: 'updates'),
        incrementPaidCount: any(named: 'incrementPaidCount'),
      )).thenAnswer((_) async => {});

      await passengerService.updateOperationalStatus(
        passengerId: 'p1',
        excursionId: 'ex1',
        updates: {'depositValue': 100.0},
      );

      verify(() => mockRepo.updateOperationalBatch(
        passengerId: 'p1',
        excursionId: 'ex1',
        updates: any(named: 'updates', that: containsPair('isPaid', true)),
        incrementPaidCount: true,
      )).called(1);
    });
  });
}
