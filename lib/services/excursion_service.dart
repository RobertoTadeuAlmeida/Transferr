import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';
import '../repositories/excursion_repository.dart';
import '../repositories/passenger_repository.dart';

class ExcursionService {
  final ExcursionRepository _excursionRepo;
  final PassengerRepository _passengerRepo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExcursionService(this._excursionRepo, this._passengerRepo);

  // =========================================================================
  // OPERAÇÕES DE EXCURSÃO COM LÓGICA DE NEGÓCIO
  // =========================================================================

  Stream<List<Excursion>> watchExcursions({String? responsibleId}) {
    return _excursionRepo.watchExcursions(responsibleId: responsibleId);
  }

  Future<void> createExcursion(Excursion excursion) async {
    return _excursionRepo.add(excursion);
  }

  Future<void> updateExcursion(Excursion excursion) async {
    return _excursionRepo.update(excursion.id, excursion.toMap());
  }

  Future<void> deleteExcursions(List<String> ids) async {
    return _excursionRepo.deleteMany(ids);
  }

  // =========================================================================
  // SINCRONIZAÇÃO E CÁLCULOS
  // =========================================================================

  /// Recalcula e sincroniza os contadores de assentos e pagamentos de uma excursão.
  Future<void> syncExcursionCounters(String excursionId) async {
    final vacanciesSnapshot = await _excursionRepo
        .watchVacancies(excursionId)
        .first;

    int totalReservados = 0;
    int totalPagos = 0;
    double faturamentoAtual = 0;

    for (var doc in vacanciesSnapshot.docs) {
      final pDoc = await _firestore.collection('passageiros').doc(doc.id).get();
      if (!pDoc.exists) {
        await doc.reference.delete();
        continue;
      }

      totalReservados++;
      final data = doc.data();
      final valorPago = (data['depositValue'] ?? 0.0).toDouble();
      faturamentoAtual += valorPago;

      final bool pago = data['isPaid'] ?? false;
      if (pago) {
        totalPagos++;
      }
    }

    await _excursionRepo.update(excursionId, {
      'assentosReservados': totalReservados,
      'assentosPagos': totalPagos,
      'faturamentoAtual': faturamentoAtual,
      'ultimaSincronizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Calcula o progresso de pagamento de um passageiro.
  /// Retorna o valor faltante e percentual para a UI.
  Future<Map<String, dynamic>> calculatePassengerPaymentProgress(
    String passengerId,
    String excursionId,
  ) async {
    final excursion = await _excursionRepo.getExcursionById(excursionId);
    if (excursion == null) throw Exception("Excursão não encontrada.");

    final vagaDoc = await _firestore
        .collection('excursoes')
        .doc(excursionId)
        .collection('vagas')
        .doc(passengerId)
        .get();

    if (!vagaDoc.exists) throw Exception("Vaga não encontrada.");

    final data = vagaDoc.data()!;
    final double valorPago = (data['depositValue'] ?? 0.0).toDouble();
    final double precoBase = excursion.basePrice;

    final double valorFaltante = precoBase - valorPago;
    final bool estaPago = valorPago >= precoBase;
    final double percentual = precoBase > 0 
        ? (valorPago / precoBase).clamp(0.0, 1.0) 
        : 0.0;

    await vagaDoc.reference.update({'isPaid': estaPago});
    await syncExcursionCounters(excursionId);

    return {
      'valorPago': valorPago,
      'valorFaltante': valorFaltante < 0 ? 0.0 : valorFaltante,
      'estaPago': estaPago,
      'percentual': percentual,
      'precoBase': precoBase,
    };
  }

  Stream<double> streamTotalRevenue(String excursionId) {
    return _excursionRepo.watchVacancies(excursionId).map((snap) {
      double total = 0;
      for (var doc in snap.docs) {
        final val = doc.data()['depositValue'];
        total += (val is num) ? val.toDouble() : 0.0;
      }
      return total;
    });
  }

  // =========================================================================
  // OPERAÇÕES DE DESPESAS
  // =========================================================================

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
