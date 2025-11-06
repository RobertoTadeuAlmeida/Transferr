import 'package:flutter/material.dart';
import 'package:transferr/models/excursion.dart';
import 'package:transferr/repositories/excursion_repository.dart';

class ExcursionProvider with ChangeNotifier {
  final ExcursionRepository _repository = ExcursionRepository();

  // O estado que a UI irá ouvir
  List<Excursion> _excursions = [];
  bool _isLoading = false;

  List<Excursion> get excursions => _excursions;

  bool get isLoading => _isLoading;

  // Calcula a receita bruta total de todas as excursões
  double get totalGrossRevenue {
    return _excursions.fold(
      0.0,
      (sum, excursion) => sum + excursion.grossRevenue,
    );
  }

  // Calcula a receita líquida total
  double get totalNetRevenue {
    return _excursions.fold(
      0.0,
      (sum, excursion) => sum + excursion.netRevenue,
    );
  }

  // Calcula total de clientes confirmados (assentos ocupados)
  int get totalClientsConfirmed {
    return _excursions.fold(
      0,
      (sum, excursion) => sum + excursion.totalClientsConfirmed,
    );
  }

  // ------ EXEMPLOS PARA PAGAMENTOS E ASSENTOS ------
  int get totalAvailableSeats {
    const int totalCapacity = 67;
    return totalCapacity - totalClientsConfirmed;
  }

  int get totalPayments {
    return _excursions.fold(
      0,
      (sum, excursion) => sum + (excursion.participants?.length ?? 0),
    );
  }

  int get completePayments {
    int count = 0;
    for (var excursion in _excursions) {
      count +=
          excursion.participants
              ?.where((p) => p.paymentStatus == PaymentStatus.paid)
              .length ??
          0;
    }
    return count;
  }

  // ------ FIM DOS EXEMPLOS ------)

  ExcursionProvider() {
    // Inicia ouvindo as mudanças no banco de dados assim que o provider é criado.
    _listenToExcursions();
  }

  void _listenToExcursions() {
    _isLoading = true;
    notifyListeners();

    _repository.getExcursionsStream().listen((excursionsList) {
      _excursions = excursionsList;
      _isLoading = false;
      notifyListeners(); // Notifica a UI que a lista foi atualizada!
    });
  }

  // Funções CRUD que a UI pode chamar
  Future<void> addExcursion(Excursion newExcursion) async {
    await _repository.addExcursion(newExcursion);
    // Não precisa chamar notifyListeners(), pois a Stream já faz isso!
  }

  Future<void> updateExcursion(Excursion updatedExcursion) async {
    await _repository.updateExcursion(updatedExcursion);
  }

  Future<void> deleteExcursion(String excursionId) async {
    await _repository.deleteExcursion(excursionId as Excursion);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'agendada':
        return Colors.blueAccent;
      case 'confirmada':
        return Colors.greenAccent;
      case 'cancelada':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

}
