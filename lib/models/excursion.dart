// lib/models/excursion.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para o getStatusColor

class Excursion {
  final String id;
  final String name;
  final DateTime date;
  final double price;
  final int totalSeats;
  final String location;
  final String description;
  String status;

  // Informações sobre os participantes/clientes

  final List<Participant> participants; // Lista de participantes

  Excursion({
    required this.id,
    required this.name,
    required this.date,
    required this.price,
    required this.totalSeats,
    required this.location,
    this.description = '',
    required this.status,
    this.participants = const [],
  });

  // --- GETTERS (Campos Calculados) ---

  int get totalClientsConfirmed {
    return participants
        .where((p) => p.status == ParticipantStatus.confirmed)
        .length;
  }

  int get availableSeats {
    return totalSeats - totalClientsConfirmed;
  }

  double get grossRevenue {
    return totalClientsConfirmed * price;
  }

  double get netRevenue {
    // Exemplo: return grossRevenue - (custosDaExcursao ?? 0.0);
    return grossRevenue;
  }

  int get totalPaymentsMade {
    // Total de pagamentos confirmados
    return participants
        .where((p) => p.paymentStatus == PaymentStatus.paid)
        .length;
  }

  int get pendingPayments {
    return participants
        .where(
          (p) =>
              p.status == ParticipantStatus.confirmed &&
              p.paymentStatus == PaymentStatus.pending,
        )
        .length;
  }

  bool get isFull {
    return availableSeats <= 0;
  }

  bool get hasPassed {
    return date.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    ); // Considera que passou no dia seguinte
  }

  // --- MÉTODOS UTILITÁRIOS ---

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'planejada':
        return Colors.blue.shade600;
      case 'confirmada':
        return Colors.green.shade600;
      case 'cancelada':
        return Colors.red.shade600;
      case 'realizada':
        return Colors.blueGrey.shade600;
      case 'lotada':
        return Colors.orange.shade800;
      default:
        return Colors.grey;
    }
  }

  // Método para adicionar um participante (exemplo)
  // Esta lógica pode ser mais complexa e viver no Provider também
  Excursion addParticipant(Participant newParticipant) {
    // Verifica se há assentos disponíveis, etc.
    if (availableSeats > 0) {
      final updatedParticipants = List<Participant>.from(participants)
        ..add(newParticipant);
      // Poderia também atualizar o status para 'Lotada' se for o caso
      String newStatus = status;
      if (totalSeats -
              (totalClientsConfirmed +
                  (newParticipant.status == ParticipantStatus.confirmed
                      ? 1
                      : 0)) <=
          0) {
        newStatus = 'Lotada';
      }
      return copyWith(participants: updatedParticipants, status: newStatus);
    }
    return this; // Retorna a instância original se não puder adicionar
  }

  // --- CONSTRUTORES E MÉTODOS DE CONVERSÃO ---

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'price': price,
      'totalSeats': totalSeats,
      'location': location,
      'description': description,
      'status': status,
      'participants': participants.map((p) => p.toMap()).toList(),
    };
  }

  factory Excursion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Excursion(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      totalSeats: data['totalSeats'] as int? ?? 0,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Planejada',
      participants:
          (data['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Método copyWith (muito útil para imutabilidade e gerenciamento de estado)
  Excursion copyWith({
    String? id,
    String? name,
    DateTime? date,
    double? price,
    int? totalSeats,
    String? location,
    String? description,
    String? status,
    List<Participant>? participants,
  }) {
    return Excursion(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      participants: participants ?? this.participants,
    );
  }
}

// --- Modelo para Participante (exemplo) ---
// Você pode criar um arquivo separado models/participant.dart
enum ParticipantStatus { pending, confirmed, cancelled }

enum PaymentStatus { pending, paid, refunded }

class Participant {
  final String clientId; // ID do cliente (referência ao seu modelo Client)
  final String clientName; // Para exibição rápida, pode ser denormalizado
  final DateTime registrationDate;
  ParticipantStatus status;
  PaymentStatus paymentStatus;
  double amountPaid;

  Participant({
    required this.clientId,
    required this.clientName,
    required this.registrationDate,
    this.status = ParticipantStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.amountPaid = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'status': status
          .toString()
          .split('.')
          .last, // Salva como string 'confirmed'
      'paymentStatus': paymentStatus
          .toString()
          .split('.')
          .last, // Salva como string 'paid'
      'amountPaid': amountPaid,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      registrationDate:
          (map['registrationDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: ParticipantStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ParticipantStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
