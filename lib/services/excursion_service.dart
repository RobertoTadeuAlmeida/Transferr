import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/excursion.dart';
import '../models/expense.dart';
import '../repositories/excursion_repository.dart';

class ExcursionService {
  final ExcursionRepository _excursionRepo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Adicionado para transações se necessário

  ExcursionService(this._excursionRepo);

  // =========================================================================
  // OPERAÇÕES DE EXCURSÃO COM LÓGICA DE NEGÓCIO
  // =========================================================================

  Future<void> createExcursion(Excursion excursion) async {
    return _excursionRepo.add(excursion);
  }

  Future<void> updateExcursion(Excursion excursion) async {
    return _excursionRepo.update(excursion.id, excursion.toMap());
  }

  Future<void> deleteExcursions(List<String> ids) async {
    // No futuro, adicionar lógica para marcar passageiros como "sem excursão" antes de deletar
    return _excursionRepo.deleteMany(ids);
  }

  // =========================================================================
  // SINCRONIZAÇÃO E CÁLCULOS
  // =========================================================================

  /// Recalcula e sincroniza os contadores de assentos e pagamentos de uma excursão.
  Future<void> syncExcursionCounters(String excursionId) async {
    // Buscamos a foto atual das vagas (sub-coleção)
    final vacanciesSnapshot = await _excursionRepo.watchVacancies(excursionId).first;

    int totalReservados = vacanciesSnapshot.docs.length;
    int totalPagos = 0;
    double faturamentoAtual = 0;

    for (var doc in vacanciesSnapshot.docs) {
      final data = doc.data();

      // 1. Somar faturamento (dinheiro em caixa)
      final valorPago = data['depositValue'] ?? 0;
      if (valorPago is num) {
        faturamentoAtual += valorPago.toDouble();
      }

      // 2. Contabilizar Pagamentos Concluídos
      // Usamos a flag 'isPaid' que definimos no PassengerService/Provider
      final bool pago = data['isPaid'] ?? false;
      if (pago) {
        totalPagos++;
      }
    }

    // 3. Atualiza o documento principal da Excursão
    // IMPORTANTE: Os nomes das chaves aqui devem ser IGUAIS aos do Excursion.fromMap
    await _excursionRepo.update(excursionId, {
      'assentosReservados': totalReservados,
      'assentosPagos': totalPagos, // Alterado de 'pagamentosConcluidos' para bater com o Model
      'faturamentoAtual': faturamentoAtual,
      'ultimaSincronizacao': FieldValue.serverTimestamp(),
    });
  }

  /// Stream que calcula o faturamento total em tempo real (para Dashboard)
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