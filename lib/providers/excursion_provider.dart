import 'dart:async';
import 'package:flutter/material.dart';
import '../models/excursion.dart';
import '../models/enums.dart';
import '../models/passenger.dart';
import '../repositories/excursion_repository.dart';

class ExcursionProvider with ChangeNotifier {
  final ExcursionRepository _repository = ExcursionRepository();

  // --- ESTADO ---
  List<Excursion> _excursions = [];
  bool _isLoading = false;
  StreamSubscription? _excursionSubscription;
  String? _currentUid;

  // --- GETTERS ---
  List<Excursion> get excursions => _excursions;
  bool get isLoading => _isLoading;

  /// Retorna apenas excursões "Programadas" ou "Em Andamento" para a Home
  List<Excursion> get activeExcursions => _excursions
      .where((ex) =>
  ex.status == ExcursionStatus.programada ||
      ex.status == ExcursionStatus.emAndamento)
      .toList();

  ExcursionProvider() ;

  // --- SINCRONIZAÇÃO EM TEMPO REAL ---

  // Adicione o parâmetro uid
  void listenToExcursions(String? uid) {
    if (uid == null) return; // Não tenta buscar se não estiver logado

    _isLoading = true;
    _excursionSubscription?.cancel();

    // Passamos o uid para o repositório filtrar a query
    _excursionSubscription = _repository.getExcursionsStream(responsibleId: uid).listen(
          (data) {
        _excursions = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Erro na Stream de Excursões: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- OPERAÇÕES DE EXCURSÃO (CRUD) ---

  Future<void> addExcursion(Excursion excursion) async {
    _setLoading(true);
    try {
      // O repositório usa o toMap() que já limpamos para evitar o erro de cast
      final newExcursion = excursion.copyWith(idResponsible: _currentUid);
      await _repository.addExcursion(excursion);
    } catch (e) {
      debugPrint("Erro ao adicionar excursão: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateExcursion(Excursion excursion) async {
    _setLoading(true);
    try {
      await _repository.updateExcursion(excursion);
    } catch (e) {
      debugPrint("Erro ao atualizar excursão: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMultipleExcursions(List<String> ids) async {
    _setLoading(true);
    try {
      await _repository.deleteMultipleExcursions(ids);
    } catch (e) {
      debugPrint("Erro ao deletar múltiplas: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- GESTÃO DE PASSAGEIROS & CHECK-IN ---

  /// Retorna o Stream de passageiros (importante para a tela de lista de passageiros)
  Stream<List<Passenger>> getPassengersStream(String excursionId) {
    return _repository.getPassengersStream(excursionId);
  }

  Future<void> addOrUpdatePassenger(String excursionId, Passenger passenger) async {
    try {
      await _repository.addOrUpdatePassenger(excursionId, passenger);
    } catch (e) {
      debugPrint("Erro ao gerir passageiro: $e");
      rethrow;
    }
  }

  Future<void> registerCheckin({
    required String excursionId,
    required String passengerId,
    required String status,
    required String agenteId,
  }) async {
    final checkinData = {
      'statusEmbarque': status,
      'agenteResponsavel': agenteId,
      'dataCheckin': DateTime.now().toIso8601String(),
    };

    try {
      await _repository.updateCheckinStatus(
        excursionId: excursionId,
        passengerId: passengerId,
        checkinData: checkinData,
      );
    } catch (e) {
      debugPrint("Erro no check-in: $e");
      rethrow;
    }
  }

  // --- AUXILIARES ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _excursionSubscription?.cancel();
    super.dispose();
  }
}