import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/models/participant.dart';
import 'enums.dart';

class Excursion {
  final String? id;
  final String name;
  final DateTime date;
  final double price;
  final int totalSeats;
  final double pricePerPerson;
  final String location;
  final String description;
  final ExcursionStatus status;
  final List<Participant> participants;
  final bool isFeatured;

  Excursion({
    this.id,
    required this.name,
    required this.date,
    required this.price,
    required this.totalSeats,
    required this.pricePerPerson,
    required this.location,
    this.description = '',
    ExcursionStatus? status,
    this.participants = const [],
    this.isFeatured = false,
  }) : status = status ?? ExcursionStatus.agendada;

  // --- GETTERS (Campos Calculados) ---

  // --- GETTERS (Campos Calculados) ---

  // ----------- GETTERS DE PARTICIPANTES -----------

  /// Retorna a contagem de participantes com o status 'free' (Cortesia).
  int get totalFreeParticipants =>
      participants.where((p) => p.paymentStatus == PaymentStatus.free).length;

  /// Retorna a contagem de participantes com o status 'pending'.
  int get totalPendingParticipants => participants
      .where((p) => p.paymentStatus == PaymentStatus.pending)
      .length;

  /// Retorna a contagem de participantes que efetivamente pagaram algo (valor > 0).
  int get totalPayingParticipants =>
      participants.where((p) => p.amountPaid > 0).length;

  /// Retorna a contagem de participantes com pagamento totalmente concluído.
  int get totalPaidParticipants =>
      participants.where((p) => p.paymentStatus == PaymentStatus.paid).length;

  // ----------- GETTERS FINANCEIROS -----------

  /// Retorna o faturamento ESPERADO dos participantes atuais (desconsiderando os de cortesia).
  /// Útil para saber quanto você DEVERIA receber dos participantes já inscritos.
  double get expectedRevenueFromConfirmed {
    return totalSeats * pricePerPerson;
  }

  /// Retorna a renda bruta REAL, somando o que todos os participantes efetivamente pagaram.
  double get grossRevenue {
    if (participants.isEmpty) return 0.0;
    return participants.fold(0.0, (sum, p) => sum + p.amountPaid);
  }

  /// Retorna a renda líquida. Por enquanto, é igual à bruta, mas está pronto para futura implementação de custos.
  double get netRevenue {
    // TODO: Implementar a lógica de custos. Ex: return grossRevenue - custos;
    return grossRevenue;
  }

  // ----------- GETTERS DE STATUS E CAPACIDADE -----------

  /// Retorna o número de assentos ainda disponíveis.
  int get availableSeats => totalSeats - participants.length;

  /// Retorna `true` se todos os assentos estiverem ocupados.
  bool get isFull => availableSeats <= 0;

  /// Retorna `true` se a data da excursão já passou.
  bool get hasPassed =>
      date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

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
      'pricePerPerson': pricePerPerson,
      'location': location,
      'description': description,
      'status': status.toString().split('.').last,
      'participants': participants.map((p) => p.toMap()).toList(),
      'isFeatured': isFeatured,
    };
  }

  factory Excursion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String statusString = data['status'] ?? 'agendada';

    ExcursionStatus statusEnum = ExcursionStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => ExcursionStatus.agendada,
    );

    return Excursion(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      totalSeats: data['totalSeats'] as int? ?? 0,
      pricePerPerson: (data['pricePerPerson'] as num?)?.toDouble() ?? 0.0,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      status: statusEnum,
      isFeatured: data['isFeatured'] ?? false,

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
    double? pricePerPerson,
    String? location,
    String? description,
    ExcursionStatus? status,
    List<Participant>? participants,
    bool? isFeatured,
  }) {
    return Excursion(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
