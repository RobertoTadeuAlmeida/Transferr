// lib/models/participant.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';class Participant {
  final String clientId;
  final String name;
  final DateTime registrationDate;
  final ParticipantStatus status;
  final PaymentStatus paymentStatus;
  final double amountPaid;

  Participant({
    required this.clientId,
    required this.name,
    required this.registrationDate,
    this.status = ParticipantStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.amountPaid = 0.0,
  });

  /// Converte o objeto Participant em um Map para o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'name': name,
      'registrationDate': Timestamp.fromDate(registrationDate),
      // MELHORIA: Usa .name, que é a forma canônica e mais segura.
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'amountPaid': amountPaid,
    };
  }

  /// Cria um objeto Participant a partir de um Map vindo do Firestore.
  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      clientId: map['clientId'] ?? '',
      name: map['name'] ?? '',
      registrationDate: (map['registrationDate'] as Timestamp? ?? Timestamp.now()).toDate(),

      // MELHORIA: A comparação usando .name é mais limpa e robusta.
      status: ParticipantStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ParticipantStatus.pending, // Valor padrão seguro
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending, // Valor padrão seguro
      ),
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
