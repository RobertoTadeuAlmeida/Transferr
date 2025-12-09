import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transferr/models/excursion.dart';
import '../models/enums.dart';
import '../models/participant.dart';

class ExcursionProvider with ChangeNotifier {
  // --- Estado e Conexão com Firebase ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _excursionsRef;
  StreamSubscription? _excursionSubscription;

  double _totalGrossRevenue = 0.0;
  double _totalNetRevenue = 0.0;
  int _totalClientsConfirmed = 0;
  int _totalAvailableSeats = 0;
  int _totalPayments = 0;
  int _completePayments = 0;
  int _totalSeatsOfAllExcursions =0;


  List<Excursion> _excursions = [];
  bool _isLoading = true;

  // --- Getters Públicos ---
  List<Excursion> get excursions => _excursions;

  bool get isLoading => _isLoading;

  double get totalGrossRevenue => _totalGrossRevenue;

  double get totalNetRevenue => _totalNetRevenue;

  int get totalClientsConfirmed => _totalClientsConfirmed;

  int get totalAvailableSeats => _totalAvailableSeats;

  int get totalPayments => _totalPayments;

  int get completePayments => _completePayments;

  int get totalSeatsOfAllExcursions => _totalSeatsOfAllExcursions;


  ExcursionProvider() {
    _excursionsRef = _firestore.collection('excursions');
    listenToExcursions();
  }

  // --- Lógica de "Ouvinte" em Tempo Real ---
  void listenToExcursions() {
    _isLoading = true;
    notifyListeners();

    _excursionSubscription?.cancel(); // Cancela ouvintes antigos

    _excursionSubscription = _excursionsRef
        .orderBy('date', descending: false)
        .snapshots() // A mágica do tempo real!
        .listen(
          (QuerySnapshot snapshot) {
        _excursions = snapshot.docs.map((doc) {
          // O cast para DocumentSnapshot é importante
          return Excursion.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList();

        _calculoTotals();

        // Só muda o estado de loading na primeira carga bem-sucedida
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners(); // Notifica a UI sobre os novos dados
      },
      onError: (error) {
        print("====== ERRO NO STREAM DO FIREBASE ======");
        print("Erro ao ouvir excursões: $error");
        print(
            "Verifique as Regras de Segurança do Firestore no console do Firebase!");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _calculoTotals() {

    int tempTotalSeats = 0;
    double tempGross = 0;
    double tempNet = 0;
    int tempClients = 0;
    int tempTotalPayments = 0;
    int tempCompletePayments = 0;
    const int totalCapacity = 67; // Mova para uma constante global se preferir

    // Itera sobre a lista uma única vez para calcular tudo.
    for (final excursion in _excursions) {
      tempTotalSeats += excursion.totalSeats;
      tempGross += excursion.grossRevenue;
      tempNet += excursion.netRevenue;
      tempClients += excursion.totalClientsConfirmed;
      tempTotalPayments += excursion.participants.length;
      tempCompletePayments += excursion.participants
          .where((p) => p.paymentStatus == PaymentStatus.paid)
          .length;
    }

    // Atualiza as variáveis de estado
    _totalSeatsOfAllExcursions = tempTotalSeats;
    _totalGrossRevenue = tempGross;
    _totalNetRevenue = tempNet;
    _totalClientsConfirmed = tempClients;
    _totalAvailableSeats = totalCapacity - _totalClientsConfirmed;
    _totalPayments = tempTotalPayments;
    _completePayments = tempCompletePayments;
  }

  // --- Funções CRUD (Create, Read, Update, Delete) ---

  Future<void> addExcursion(Excursion newExcursion) async {
    try {
      await _excursionsRef.add(newExcursion.toMap());
    } catch (e) {
      print('Erro ao adicionar excursão: $e');
      throw e;
    }
  }

  Future<void> updateExcursion(Excursion updatedExcursion) async {
    if (updatedExcursion.id == null) {
      throw Exception('ID da excursão não pode ser nulo para atualização.');
    }
    try {
      await _excursionsRef.doc(updatedExcursion.id).update(
          updatedExcursion.toMap());
    } catch (e) {
      print('Erro ao atualizar excursão: $e');
      throw e;
    }
  }

  // 3. CORRIGIDO: Agora aceita uma String, que é mais simples
  Future<void> deleteExcursion(String excursionId) async {
    try {
      await _excursionsRef.doc(excursionId).delete();
    } catch (e) {
      print('Erro ao deletar excursão: $e');
      throw e;
    }
  }


  // --- Métodos Utilitários ---

  Color getStatusColor(ExcursionStatus status) {
    // Seu switch de cores está perfeito
    switch (status) {
      case ExcursionStatus.scheduled:
        return Colors.blueAccent;
      case ExcursionStatus.confirmed:
        return Colors.greenAccent;
      case ExcursionStatus.completed:
        return Colors.purpleAccent;
      case ExcursionStatus.canceled:
        return Colors.redAccent;
    }
  }

  Excursion? getExcursionById(String excursionId) {
    try {
      return _excursions.firstWhere((ex) => ex.id == excursionId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _excursionSubscription?.cancel();
    super.dispose();
  }
}
