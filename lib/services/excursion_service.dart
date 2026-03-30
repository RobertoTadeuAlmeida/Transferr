import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';
import '../models/enums.dart';
import '../repositories/excursion_repository.dart';
import '../repositories/passenger_repository.dart';

class ExcursionService {
  final ExcursionRepository _excursionRepo;
  final PassengerRepository _passengerRepo;

  ExcursionService(this._excursionRepo, this._passengerRepo);

  Stream<List<Excursion>> watchExcursions({String? companyId}) {
    return _excursionRepo.watchExcursions(companyId: companyId);
  }

  Future<void> createExcursion(Excursion excursion) async {
    final sanitizedName = excursion.name.trim();
    if (sanitizedName.isEmpty) {
      throw Exception("O nome da excursão é obrigatório.");
    }
    return _excursionRepo.add(excursion.copyWith(name: sanitizedName));
  }

  Future<void> updateExcursion(Excursion excursion) async {
    final sanitizedName = excursion.name.trim();
    if (sanitizedName.isEmpty) {
      throw Exception("O nome da excursão não pode ficar vazio.");
    }
    return _excursionRepo.update(excursion.id, excursion.copyWith(name: sanitizedName).toMap());
  }

  Future<void> deleteExcursions(List<String> ids) async {
    // Agora o Repository cuida do Batch de soft delete
    return _excursionRepo.softDeleteMany(ids);
  }

  Future<void> startExcursion(String excursionId) async {
    final excursion = await _excursionRepo.getExcursionById(excursionId);
    if (excursion == null) throw Exception("Excursão não encontrada.");

    if (excursion.status == ExcursionStatus.concluida || excursion.status == ExcursionStatus.cancelada) {
      throw Exception("Não é possível iniciar uma viagem finalizada ou cancelada.");
    }

    return _excursionRepo.update(excursionId, {
      'status': 'EM_ANDAMENTO',
      'dataInicioReal': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finalizeExcursion(String excursionId) async {
    final vacanciesSnap = await _excursionRepo.getVacancies(excursionId);
    
    int totalEfetivo = 0;
    List<Map<String, dynamic>> passengerUpdates = [];

    for (var vacancyDoc in vacanciesSnap.docs) {
      final data = vacancyDoc.data();
      final String statusEmbarque = data['statusEmbarque'] ?? '';
      
      final isBoarded = statusEmbarque == BoardingStatus.embarcou.value || 
                        statusEmbarque == BoardingStatus.desembarcou.value ||
                        statusEmbarque == BoardingStatus.parada.value;

      if (isBoarded) totalEfetivo++;

      // Prepara os dados de atualização do passageiro no CRM
      passengerUpdates.add({
        'id': vacancyDoc.id,
        'data': {
          if (isBoarded) 'totalViagens': FieldValue.increment(1),
          if (isBoarded) 'tripHistory': FieldValue.arrayUnion([excursionId]),
          'excursionId': null,
          'poltrona': '',
          'depositValue': 0.0,
          'isPaid': false,
          'statusEmbarque': BoardingStatus.aguardando.value,
          'lastUpdate': FieldValue.serverTimestamp(),
        }
      });
    }

    // O Repository executa o Batch atômico
    return _excursionRepo.finalizeExcursionBatch(
      excursionId: excursionId,
      passengerUpdates: passengerUpdates,
      totalEfetivo: totalEfetivo,
    );
  }

  Future<void> cancelExcursion(String excursionId) async {
    return _excursionRepo.update(excursionId, {'status': 'CANCELADA'});
  }

  Future<void> syncExcursionCounters(String excursionId) async {
    final vacanciesSnapshot = await _excursionRepo.watchVacancies(excursionId).first;

    int totalReservados = 0;
    int totalPagos = 0;
    double faturamentoAtual = 0;

    for (var doc in vacanciesSnapshot.docs) {
      final data = doc.data();
      totalReservados++;
      final valorPago = (data['depositValue'] ?? 0.0).toDouble();
      faturamentoAtual += valorPago;
      if (data['isPaid'] == true) totalPagos++;
    }

    await _excursionRepo.update(excursionId, {
      'assentosReservados': totalReservados,
      'assentosPagos': totalPagos,
      'faturamentoAtual': faturamentoAtual,
    });
  }

  Future<Map<String, dynamic>> calculatePassengerPaymentProgress(
    String passengerId,
    String excursionId,
  ) async {
    final excursion = await _excursionRepo.getExcursionById(excursionId);
    if (excursion == null) throw Exception("Excursão não encontrada.");

    // O Repository cuida da Transação
    final result = await _excursionRepo.runPaymentTransaction(
      excursionId: excursionId,
      passengerId: passengerId,
      precoBase: excursion.basePrice,
    );

    await syncExcursionCounters(excursionId);
    return result;
  }

  Stream<double> streamTotalRevenue(String excursionId) {
    return _excursionRepo.watchVacancies(excursionId).map((snap) {
      return snap.docs.fold(0.0, (sum, doc) => sum + (doc.data()['depositValue'] ?? 0.0).toDouble());
    });
  }

  Stream<List<Expense>> watchExpenses(String excursionId) {
    return _excursionRepo.watchExpenses(excursionId);
  }

  Future<void> addExpense(String excursionId, Expense expense) async {
    return _excursionRepo.addExpense(excursionId, expense);
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    return _excursionRepo.deleteExpense(excursionId, expenseId);
  }
}
