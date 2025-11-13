import 'package:cloud_firestore/cloud_firestore.dart';

// Os Enums agora vivem junto com a classe que mais os utiliza.
enum ParticipantStatus { pending, confirmed, cancelled }

enum PaymentStatus { pending, paid, refunded }

class Participant {
  final String clientId; // ID do cliente (referência ao seu modelo Client)
  final String clientName; // Para exibição rápida, pode ser denormalizado
  final DateTime registrationDate;
  final ParticipantStatus status;
  final PaymentStatus paymentStatus;
  final double amountPaid;

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
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
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
