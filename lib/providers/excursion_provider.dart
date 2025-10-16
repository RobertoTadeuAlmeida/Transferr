import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/excursion.dart';
import '../main.dart';

class ExcursionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double totalGrossRevenue = 0.0;
  double totalNetRevenue = 0.0;
  int totalClientsConfirmed = 0;
  int completePayments = 0;
  int totalPayments = 0;
  int totalAvailableSeats = 100; // Valor fixo de exemplo por enquanto
  List<Excursion> excursions = [];

  // Variável para indicar se os dados estão sendo carregados
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Método para carregar todos os dados do dashboard e as excursões
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners(); // Notifica os ouvintes que o carregamento começou

    try {
      final querySnapshot = await _firestore
          .collection('artifacts') // OU 'users/${userId}/excursions'
          .doc(appId) // OU userId
          .collection('public') // OU remover se for direto em 'excursions'
          .doc('data') // OU remover
          .collection('excursions')
          .get();

      final loadedExcursions = querySnapshot.docs
          .map(
            (doc) => Excursion.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          ) // Cast aqui
          .toList();

      double calculatedGross = 0.0;
      double calculatedNet = 0.0;
      int confirmedClients = 0;
      int tempCompletePayments =
          0; // Para pagamentos completos em todas as excursões
      int tempTotalRegisteredParticipants =
          0; // Total de participantes registrados em todas as excursões

      for (var excursion in loadedExcursions) {
        calculatedGross += excursion.grossRevenue; // Usando o getter do modelo
        calculatedNet += excursion.netRevenue; // Usando o getter do modelo
        confirmedClients += excursion.totalClientsConfirmed; // Usando o getter
        tempTotalRegisteredParticipants += excursion.participants.length;
        tempCompletePayments += excursion.totalPaymentsMade; // Usando o getter
      }

      totalGrossRevenue = calculatedGross;
      totalNetRevenue = calculatedNet;
      totalClientsConfirmed = confirmedClients;
      completePayments = tempCompletePayments; // Pagamentos totais confirmados
      totalPayments =
          tempTotalRegisteredParticipants; // Total de pessoas registradas (independente do status de pagamento)

      // totalAvailableSeats no dashboard pode ser a soma dos availableSeats de todas as excursões futuras
      // ou um valor fixo se você tiver uma capacidade geral.
      // Se for a soma:
      totalAvailableSeats = loadedExcursions
          .where(
            (ex) => !ex.hasPassed && ex.status != 'Cancelada',
          ) // Excursões futuras e não canceladas
          .fold(
            0,
            (sum, ex) => sum + ex.availableSeats,
          ); // Soma dos assentos disponíveis

      excursions = loadedExcursions;

      notifyListeners();
    } catch (e) {
      print("Erro ao carregar dados do dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper para obter a cor do status
  Color getStatusColor(String status) {
    switch (status) {
      case 'Agendada':
        return Colors.orange.shade600;
      case 'Confirmada':
        return Colors.green.shade600;
      case 'Cancelada':
        return Colors.red.shade600;
      case 'Finalizada':
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey;
    }
  }
}
