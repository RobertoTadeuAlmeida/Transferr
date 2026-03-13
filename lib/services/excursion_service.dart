import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';
import '../models/enums.dart';
import '../repositories/excursion_repository.dart';
import '../repositories/passenger_repository.dart';

class ExcursionService {
  final ExcursionRepository _excursionRepo;
  final PassengerRepository _passengerRepo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExcursionService(this._excursionRepo, this._passengerRepo);

  // Alterado para usar companyId por causa das Security Rules
  Stream<List<Excursion>> watchExcursions({String? companyId}) {
    return _excursionRepo.watchExcursions(companyId: companyId);
  }

  Future<void> createExcursion(Excursion excursion) async {
    final sanitizedName = excursion.name.trim();
    if (sanitizedName.isEmpty) {
      throw Exception("O nome da excursão é obrigatório para iniciar o cadastro.");
    }
    final validatedExcursion = excursion.copyWith(name: sanitizedName);
    return _excursionRepo.add(validatedExcursion);
  }

  Future<void> updateExcursion(Excursion excursion) async {
    final sanitizedName = excursion.name.trim();
    if (sanitizedName.isEmpty) {
      throw Exception("O nome da excursão não pode ficar vazio.");
    }
    final validatedExcursion = excursion.copyWith(name: sanitizedName);
    return _excursionRepo.update(validatedExcursion.id, validatedExcursion.toMap());
  }

  Future<void> deleteExcursions(List<String> ids) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      final docRef = _firestore.collection('excursoes').doc(id);
      batch.update(docRef, {
        'excluido': true,
        'deletadoEm': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit();
  }

  Future<void> startExcursion(String excursionId) async {
    final doc = await _firestore.collection('excursoes').doc(excursionId).get();
    final currentStatus = doc.data()?['status'];

    if (currentStatus == 'CONCLUIDA' || currentStatus == 'CANCELADA') {
      throw Exception("Não é possível iniciar uma viagem que já foi finalizada ou cancelada.");
    }

    try {
      await _excursionRepo.update(excursionId, {
        'status': 'EM_ANDAMENTO',
        'dataInicioReal': FieldValue.serverTimestamp(),
        'ultimaSincronizacao': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> finalizeExcursion(String excursionId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final excursionRef = _firestore.collection('excursoes').doc(excursionId);
      final vacanciesSnap = await excursionRef.collection('vagas').get();
      
      int totalEfetivo = 0;

      for (var vacancyDoc in vacanciesSnap.docs) {
        final data = vacancyDoc.data();
        final String statusEmbarque = data['statusEmbarque'] ?? '';
        final passengerId = vacancyDoc.id;
        final masterRef = _firestore.collection('passageiros').doc(passengerId);

        if (statusEmbarque == BoardingStatus.embarcou.value || 
            statusEmbarque == BoardingStatus.desembarcou.value ||
            statusEmbarque == BoardingStatus.parada.value) {
          
          totalEfetivo++;
          batch.update(masterRef, {
            'totalViagens': FieldValue.increment(1),
            'tripHistory': FieldValue.arrayUnion([excursionId]),
          });
        }

        batch.update(masterRef, {
          'excursionId': null,
          'poltrona': '',
          'depositValue': 0.0,
          'isPaid': false,
          'statusEmbarque': BoardingStatus.aguardando.value,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }

      batch.update(excursionRef, {
        'status': 'CONCLUIDA',
        'dataFimReal': FieldValue.serverTimestamp(),
        'assentosEfetivos': totalEfetivo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelExcursion(String excursionId) async {
    try {
      await _excursionRepo.update(excursionId, {
        'status': 'CANCELADA',
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
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
      'ultimaSincronizacao': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> calculatePassengerPaymentProgress(
    String passengerId,
    String excursionId,
  ) async {
    return await _firestore.runTransaction((transaction) async {
      final excursionDoc = await transaction.get(_firestore.collection('excursoes').doc(excursionId));
      if (!excursionDoc.exists) throw Exception("Excursão não encontrada.");
      
      final excursion = Excursion.fromMap(excursionDoc.id, excursionDoc.data()!);
      final vacancyRef = _firestore.collection('excursoes').doc(excursionId).collection('vagas').doc(passengerId);
      final vacancyDoc = await transaction.get(vacancyRef);

      if (!vacancyDoc.exists) throw Exception("Vaga não encontrada.");

      final double valorPago = (vacancyDoc.data()?['depositValue'] ?? 0.0).toDouble();
      final double precoBase = excursion.basePrice;
      final bool estaPago = valorPago >= precoBase;

      transaction.update(vacancyRef, {'isPaid': estaPago});
      
      return {
        'valorPago': valorPago,
        'valorFaltante': (precoBase - valorPago).clamp(0.0, double.infinity),
        'estaPago': estaPago,
        'percentual': precoBase > 0 ? (valorPago / precoBase).clamp(0.0, 1.0) : 0.0,
        'precoBase': precoBase,
      };
    }).then((result) async {
      await syncExcursionCounters(excursionId);
      return result;
    });
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
    await _excursionRepo.addExpense(excursionId, expense);
  }

  Future<void> deleteExpense(String excursionId, String expenseId) async {
    await _excursionRepo.deleteExpense(excursionId, expenseId);
  }
}
