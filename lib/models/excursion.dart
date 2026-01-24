import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class Excursion {
  final String? id;final String name;
  final String description;
  final String idMainDestination;
  final DateTime startDate; // dataPartida
  final DateTime returnDate; // dataRetorno
  final double basePrice; // precoBase
  final int totalSeats; // assentosTotais
  final int reservedSeats; // assentosReservados
  final String slug;
  final ExcursionStatus status;
  final String idResponsible; // idResponsavel (Admin/Dono)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Excursion({
    this.id,
    required this.name,
    this.description = '',
    required this.idMainDestination,
    required this.startDate,
    required this.returnDate,
    required this.basePrice,
    required this.totalSeats,
    this.reservedSeats = 0,
    required this.slug,
    this.status = ExcursionStatus.emAndamento,
    required this.idResponsible,
    this.createdAt,
    this.updatedAt,
  });

  // ----------- GETTERS LOGICOS -----------

  int get availableSeats => totalSeats - reservedSeats;

  bool get isFull => availableSeats <= 0;

  // ----------- CONVERSÃO FIRESTORE -----------

  Map<String, dynamic> toMap() {
    return {
      'nome': name,
      'descricao': description,
      'idDestinoPrincipal': idMainDestination,
      'dataPartida': Timestamp.fromDate(startDate),
      'dataRetorno': Timestamp.fromDate(returnDate),
      'precoBase': basePrice,
      'assentosTotais': totalSeats,
      'assentosReservados': reservedSeats,
      'slug': slug,
      'status': status.name.toUpperCase(), // Salva como 'EM_ANDAMENTO'
      'idResponsavel': idResponsible,
      'criadoEm': createdAt ?? FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Excursion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Excursion(
      id: doc.id,
      name: data['nome'] ?? '',
      description: data['descricao'] ?? '',
      idMainDestination: data['idDestinoPrincipal'] ?? '',
      startDate: (data['dataPartida'] as Timestamp).toDate(),
      returnDate: (data['dataRetorno'] as Timestamp).toDate(),
      basePrice: (data['precoBase'] as num?)?.toDouble() ?? 0.0,
      totalSeats: data['assentosTotais'] as int? ?? 0,
      reservedSeats: data['assentosReservados'] as int? ?? 0,
      slug: data['slug'] ?? '',
      idResponsible: data['idResponsavel'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: (data['criadoEm'] as Timestamp?)?.toDate(),
      updatedAt: (data['atualizadoEm'] as Timestamp?)?.toDate(),
    );
  }

  static ExcursionStatus _parseStatus(String? status) {
    switch (status) {
      case 'EM_ANDAMENTO':
        return ExcursionStatus.emAndamento;
      case 'CONCLUIDA':
        return ExcursionStatus.concluida;
      case 'CANCELADA':
        return ExcursionStatus.cancelada;
      default:
        return ExcursionStatus.emAndamento;
    }
  }

  Excursion copyWith({
    String? id,
    String? name,
    String? description,
    String? idMainDestination,
    DateTime? startDate,
    DateTime? returnDate,
    double? basePrice,
    int? totalSeats,
    int? reservedSeats,
    String? slug,
    ExcursionStatus? status,
    String? idResponsible,
  }) {
    return Excursion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      idMainDestination: idMainDestination ?? this.idMainDestination,
      startDate: startDate ?? this.startDate,
      returnDate: returnDate ?? this.returnDate,
      basePrice: basePrice ?? this.basePrice,
      totalSeats: totalSeats ?? this.totalSeats,
      reservedSeats: reservedSeats ?? this.reservedSeats,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      idResponsible: idResponsible ?? this.idResponsible,
    );
  }
}