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

  // --- VÍNCULO COM EXCURSÃO ATIVA ---
  final String excursionId;
  final String seatNumber;
  final double depositValue;
  final bool isPaid;
  final BoardingStatus statusEmbarque;
  final String? agenteResponsavel;

  // Armazena onde o passageiro realizou a última ação (embarque/parada/desembarque)
  final String? ultimaParada;

  // --- HISTÓRICO E METADADOS ---
  final int totalTrips;
  final DateTime? lastUpdate;

  // --- COMPOSIÇÃO ---
  final Guardian? guardian;

  Passenger({
    required this.id,
    this.excursionId = '',
    required this.name,
    required this.document,
    required this.phone,
    required this.birthDate,
    this.seatNumber = '',
    this.isMinor = false,
    this.isPaid = false,
    this.statusEmbarque = BoardingStatus.aguardando,
    this.agenteResponsavel,
    this.ultimaParada,
    this.guardian,
    this.depositValue = 0.0,
    this.totalTrips = 0,
    this.lastUpdate,
  });

  // ===========================================================================
  // REGRAS DE NEGÓCIO (GETTERS)
  // ===========================================================================

  bool get hasGuardian => isMinor && guardian != null;

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
      'nome': name,
      'documento': document,
      'telefone': phone,
      'nascimento': Timestamp.fromDate(birthDate),
      'ehMenor': isMinor,
      'poltrona': seatNumber,
      'excursaoId': excursionId.isEmpty ? null : excursionId,
      'statusEmbarque': statusEmbarque.value,
      'agenteResponsavel': agenteResponsavel,
      'ultimaParada': ultimaParada,
      'responsavel': isMinor ? guardian?.toMap() : null,
      'depositValue': depositValue,
      'isPaid': isPaid,
      'lastUpdate': FieldValue.serverTimestamp(),
      'totalViagens': totalTrips,
    };
  }

  factory Passenger.fromMap(String id, Map<String, dynamic> map) {
    return Passenger(
      id: id,
      name: map['nome'] ?? '',
      document: map['documento'] ?? '',
      phone: map['telefone'] ?? '',
      birthDate: (map['nascimento'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMinor: map['ehMenor'] ?? false,
      excursionId: map['excursaoId'] ?? map['excursionId'] ?? '',
      seatNumber: map['poltrona'] ?? '',
      statusEmbarque: BoardingStatus.fromString(map['statusEmbarque']),
      agenteResponsavel: map['agenteResponsavel'],
      ultimaParada: map['ultimaParada'],
      guardian: map['responsavel'] != null
          ? Guardian.fromMap(map['responsavel'])
          : null,
      depositValue: (map['depositValue'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      totalTrips: (map['totalViagens'] ?? 0).toInt(),
      lastUpdate: map['lastUpdate'] is Timestamp
          ? (map['lastUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  // ===========================================================================
  // IMUTABILIDADE (COPYWITH)
  // ===========================================================================

  Passenger copyWith({
    String? id,
    String? name,
    String? excursionId,
    String? document,
    String? phone,
    DateTime? birthDate,
    String? seatNumber,
    bool? isMinor,
    BoardingStatus? statusEmbarque,
    String? agenteResponsavel,
    String? ultimaParada,
    Guardian? guardian,
    double? depositValue,
    bool? isPaid,
    int? totalTrips,
    DateTime? lastUpdate,
  }) {
    return Passenger(
      id: id ?? this.id,
      name: name ?? this.name,
      excursionId: excursionId ?? this.excursionId,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      seatNumber: seatNumber ?? this.seatNumber,
      isMinor: isMinor ?? this.isMinor,
      statusEmbarque: statusEmbarque ?? this.statusEmbarque,
      agenteResponsavel: agenteResponsavel ?? this.agenteResponsavel,
      ultimaParada: ultimaParada ?? this.ultimaParada,
      guardian: guardian ?? this.guardian,
      depositValue: depositValue ?? this.depositValue,
      isPaid: isPaid ?? this.isPaid,
      totalTrips: totalTrips ?? this.totalTrips,
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
