import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Representa a entidade de Domínio do Passageiro
class Passenger {
  // --- IDENTIDADE E CONTATO ---
  final String id;
  final String name;
  final String document;
  final String phone;
  final DateTime birthDate;
  final bool isMinor;
  final String empresa; // Novo campo para Multi-tenant global

  // --- VÍNCULO COM EXCURSÃO ATIVA ---
  final String? excursionId; 
  final String seatNumber;
  final double depositValue;
  final double saleValue; // Novo campo: Preço acordado no momento da venda (Escalabilidade)
  final bool isPaid;
  final BoardingStatus statusEmbarque;

  // --- HISTÓRICO E METADADOS ---
  final int totalTrips;
  final List<String> tripHistory; 
  final DateTime? lastUpdate;

  // --- COMPOSIÇÃO ---
  final Guardian? guardian;

  Passenger({
    required this.id,
    required this.empresa,
    this.excursionId,
    required this.name,
    required this.document,
    required this.phone,
    required this.birthDate,
    this.seatNumber = '',
    this.isMinor = false,
    this.isPaid = false,
    this.statusEmbarque = BoardingStatus.aguardando,
    this.guardian,
    this.depositValue = 0.0,
    this.saleValue = 0.0,
    this.totalTrips = 0,
    this.tripHistory = const [],
    this.lastUpdate,
  });

  // ===========================================================================
  // REGRAS DE NEGÓCIO (GETTERS)
  // ===========================================================================

  bool get isCurrentlyTraveling => excursionId != null && excursionId!.isNotEmpty && excursionId != "null";

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // ===========================================================================
  // MAPEAMENTO (DATA TRANSFER OBJECT PATTERN)
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa': empresa,
      'nome': name,
      'documento': document,
      'telefone': phone,
      'nascimento': Timestamp.fromDate(birthDate),
      'ehMenor': isMinor,
      'poltrona': seatNumber,
      'excursionId': excursionId,
      'statusEmbarque': statusEmbarque.value,
      'responsavel': isMinor ? guardian?.toMap() : null,
      'depositValue': depositValue,
      'saleValue': saleValue,
      'isPaid': isPaid,
      'lastUpdate': FieldValue.serverTimestamp(),
      'totalViagens': totalTrips,
      'tripHistory': tripHistory,
    };
  }

  factory Passenger.fromMap(String id, Map<String, dynamic> map) {
    return Passenger(
      id: id,
      empresa: map['empresa'] ?? '',
      name: map['nome'] ?? '',
      document: map['documento'] ?? '',
      phone: map['telefone'] ?? '',
      birthDate: (map['nascimento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMinor: map['ehMenor'] ?? false,
      excursionId: map['excursionId'] as String?,
      seatNumber: map['poltrona'] ?? '',
      statusEmbarque: BoardingStatus.fromString(map['statusEmbarque']),
      guardian: map['responsavel'] != null
          ? Guardian.fromMap(map['responsavel'])
          : null,
      depositValue: (map['depositValue'] ?? 0.0).toDouble(),
      saleValue: (map['saleValue'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      totalTrips: (map['totalViagens'] ?? 0).toInt(),
      tripHistory: List<String>.from(map['tripHistory'] ?? []),
      lastUpdate: map['lastUpdate'] is Timestamp
          ? (map['lastUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  Passenger copyWith({
    String? id,
    String? empresa,
    String? name,
    String? excursionId,
    String? document,
    String? phone,
    DateTime? birthDate,
    String? seatNumber,
    bool? isMinor,
    BoardingStatus? statusEmbarque,
    Guardian? guardian,
    double? depositValue,
    double? saleValue,
    bool? isPaid,
    int? totalTrips,
    List<String>? tripHistory,
    DateTime? lastUpdate,
  }) {
    return Passenger(
      id: id ?? this.id,
      empresa: empresa ?? this.empresa,
      name: name ?? this.name,
      excursionId: excursionId ?? this.excursionId,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      seatNumber: seatNumber ?? this.seatNumber,
      isMinor: isMinor ?? this.isMinor,
      statusEmbarque: statusEmbarque ?? this.statusEmbarque,
      guardian: guardian ?? this.guardian,
      depositValue: depositValue ?? this.depositValue,
      saleValue: saleValue ?? this.saleValue,
      isPaid: isPaid ?? this.isPaid,
      totalTrips: totalTrips ?? this.totalTrips,
      tripHistory: tripHistory ?? this.tripHistory,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class Guardian {
  final String? id;
  final String name;
  final String document;
  final String phone;

  Guardian({
    this.id,
    required this.name,
    required this.document,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': name, 'documento': document, 'telefone': phone};
  }

  factory Guardian.fromMap(Map<String, dynamic> map) {
    return Guardian(
      id: map['id'],
      name: map['nome'] ?? '',
      document: map['documento'] ?? '',
      phone: map['telefone'] ?? '',
    );
  }
}
