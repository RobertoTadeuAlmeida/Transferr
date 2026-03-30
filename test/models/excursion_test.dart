import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/models/enums.dart';

void main() {
  group('Excursion Model Tests', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final mockExcursionData = {
      'nome': 'Viagem para Arraial',
      'idDestinoPrincipal': 'arraial_01',
      'dataPartida': timestamp,
      'dataRetorno': timestamp,
      'precoBase': 150.0,
      'assentosTotais': 44,
      'assentosReservados': 10,
      'totalRecebido': 500.0,
      'slug': 'arraial-2024',
      'status': 'PROGRAMADA',
      'idResponsavel': 'user_123',
      'empresa': 'comp_abc',
    };

    test('should calculate financial metrics correctly', () {
      final excursion = Excursion.fromMap('ex_1', mockExcursionData);

      // 44 assentos * 150.0 = 6600.0
      expect(excursion.faturamentoPrevistoIdeal, 6600.0);
      
      // 10 assentos reservados * 150.0 = 1500.0
      expect(excursion.faturamentoEstimadoAtual, 1500.0);
      
      // 1500.0 (estimado) - 500.0 (recebido) = 1000.0
      expect(excursion.aReceber, 1000.0);
    });

    test('should calculate profit correctly', () {
      final excursion = Excursion.fromMap('ex_1', mockExcursionData);
      const totalDespesas = 2000.0;

      // Lucro Previsto Ideal (Lotado): 6600.0 - 2000.0 = 4600.0
      expect(excursion.calcularLucroPrevisto(totalDespesas), 4600.0);

      // Lucro Atual (Baseado no Recebido): 500.0 - 2000.0 = -1500.0
      expect(excursion.calcularLucroAtual(totalDespesas), -1500.0);
    });

    test('isFull should return true when reservations reach total seats', () {
      final excursion = Excursion.fromMap('ex_1', mockExcursionData).copyWith(
        reservedSeats: 44,
        totalSeats: 44,
      );

      expect(excursion.isFull, isTrue);
    });

    test('should convert to Map correctly for Firestore', () {
      final excursion = Excursion.fromMap('ex_1', mockExcursionData);
      final map = excursion.toMap();

      expect(map['nome'], 'Viagem para Arraial');
      expect(map['status'], 'PROGRAMADA');
      expect(map['precoBase'], 150.0);
      expect(map['dataPartida'], isA<Timestamp>());
    });

    test('should parse status correctly from String', () {
      final dataWithStatus = Map<String, dynamic>.from(mockExcursionData);
      
      dataWithStatus['status'] = 'EM_ANDAMENTO';
      expect(Excursion.fromMap('id', dataWithStatus).status, ExcursionStatus.emAndamento);

      dataWithStatus['status'] = 'CONCLUIDA';
      expect(Excursion.fromMap('id', dataWithStatus).status, ExcursionStatus.concluida);

      dataWithStatus['status'] = 'INVALIDO';
      expect(Excursion.fromMap('id', dataWithStatus).status, ExcursionStatus.programada); // Fallback
    });
  });
}
