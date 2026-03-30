import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/models/passenger.dart';
import 'package:transferr/models/enums.dart';

void main() {
  group('Passenger Model Tests', () {
    final birthDate = DateTime(2000, 1, 1);
    
    test('should calculate age correctly', () {
      final passenger = Passenger(
        id: '1',
        empresa: 'comp_1',
        name: 'Test',
        document: '123',
        phone: '999',
        birthDate: birthDate,
      );

      final expectedAge = DateTime.now().year - 2000;
      // Pode variar 1 ano dependendo do dia atual, mas o teste básico valida a lógica
      expect(passenger.age, closeTo(expectedAge, 1));
    });

    test('should identify traveling status correctly', () {
      final p1 = Passenger(id: '1', empresa: 'c', name: 'N', document: 'D', phone: 'P', birthDate: birthDate, excursionId: 'ex_123');
      final p2 = Passenger(id: '2', empresa: 'c', name: 'N', document: 'D', phone: 'P', birthDate: birthDate, excursionId: null);

      expect(p1.isCurrentlyTraveling, isTrue);
      expect(p2.isCurrentlyTraveling, isFalse);
    });

    test('should handle Minor and Guardian mapping', () {
      final guardian = Guardian(name: 'Pai', document: '999', phone: '888');
      final passenger = Passenger(
        id: '1',
        empresa: 'c',
        name: 'Menor',
        document: 'D',
        phone: 'P',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
        isMinor: true,
        guardian: guardian,
      );

      final map = passenger.toMap();
      expect(map['ehMenor'], isTrue);
      expect(map['responsavel']['nome'], 'Pai');

      final fromMap = Passenger.fromMap('1', map);
      expect(fromMap.guardian?.name, 'Pai');
    });

    test('BoardingStatus should parse correctly from string', () {
      expect(BoardingStatus.fromString('EMBARCOU'), BoardingStatus.embarcou);
      expect(BoardingStatus.fromString('INVALIDO'), BoardingStatus.aguardando);
    });
  });
}
