import 'package:flutter_test/flutter_test.dart';
import 'package:transferr/models/enums.dart';

void main() {
  group('Enum Parsing Tests', () {
    
    test('ExcursionStatus.fromString should be case-insensitive and resilient', () {
      expect(ExcursionStatus.fromString('EM_ANDAMENTO'), ExcursionStatus.emAndamento);
      expect(ExcursionStatus.fromString('programada'), ExcursionStatus.programada);
      expect(ExcursionStatus.fromString('INVALIDO'), ExcursionStatus.programada); // Fallback
      expect(ExcursionStatus.fromString(null), ExcursionStatus.programada); // Fallback
    });

    test('BoardingStatus.fromString should return correct values', () {
      expect(BoardingStatus.fromString('EMBARCOU'), BoardingStatus.embarcou);
      expect(BoardingStatus.fromString('nao_embarcou'), BoardingStatus.naoEmbarcou);
      expect(BoardingStatus.fromString('OUTRO'), BoardingStatus.aguardando); // Fallback
    });

    test('UserRole.fromString should handle roles correctly', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('agente'), UserRole.agente);
      expect(UserRole.fromString(null), UserRole.agente);
    });

    test('PaymentStatus.fromString should handle status correctly', () {
      expect(PaymentStatus.fromString('PAGO'), PaymentStatus.pago);
      expect(PaymentStatus.fromString('pendente'), PaymentStatus.pendente);
    });
  });
}
