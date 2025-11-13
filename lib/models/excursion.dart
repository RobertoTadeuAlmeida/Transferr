import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/models/participant.dart';
import 'package:transferr/providers/excursion_provider.dart';

class Excursion {
  final String id;
  final String name;
  final DateTime date;
  final double price;
  final int totalSeats;
  final String location;
  final String description;
  final ExcursionStatus? status;

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

  // Método para adicionar um participante

  Excursion addParticipant(Participant newParticipant) {
    if (availableSeats > 0) {
      final updatedParticipants = List<Participant>.from(participants)
        ..add(newParticipant);
      return copyWith(participants: updatedParticipants);
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
      'status': status.toString().split('.').last,
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
      status: ExcursionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ExcursionStatus.agendada,
      ),
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
    ExcursionStatus? status,
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