import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class Excursion {
  final String id;
  final String name;
  final String description;
  final String idMainDestination;
  final DateTime startDate;
  final DateTime returnDate;
  final double basePrice;
  final int totalSeats;
  final int reservedSeats;
  final int paidSeats;
  final String slug;
  final ExcursionStatus status;
  final String idResponsible;
  final String empresa; // NOVO: Vínculo Multi-tenant
  final bool isDeleted; // Soft Delete
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Excursion({
    required this.id,
    required this.name,
    this.description = '',
    required this.idMainDestination,
    required this.startDate,
    required this.returnDate,
    required this.basePrice,
    required this.totalSeats,
    this.reservedSeats = 0,
    this.paidSeats = 0,
    required this.slug,
    this.status = ExcursionStatus.programada,
    required this.idResponsible,
    required this.empresa, // Campo obrigatório
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  // ===========================================================================
  // ----------- LÓGICA DE NEGÓCIO (CÁLCULOS LOCAIS / DDD) -----------
  // ===========================================================================

  bool get isFull => reservedSeats > totalSeats;
  double get faturamentoPrevisto => totalSeats * basePrice;
  double get faturamentoEstimadoAtual => reservedSeats * basePrice;

  double calcularCustoPorAssento(double totalDespesas) {
    if (totalSeats <= 0) return 0.0;
    return totalDespesas / totalSeats;
  }

  double calcularLucroPrevisto(double totalDespesas) {
    return faturamentoPrevisto - totalDespesas;
  }

  double calcularLucroAtual(double faturamentoReal, double totalDespesas) {
    return faturamentoReal - totalDespesas;
  }

  // ===========================================================================
  // ----------- CONVERSÃO E PERSISTÊNCIA (FIRESTORE) -----------
  // ===========================================================================

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
      'status': _statusToString(status),
      'idResponsavel': idResponsible,
      'empresa': empresa, // Salvando no Firestore
      'excluido': isDeleted,
      'criadoEm': createdAt ?? FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  factory Excursion.fromMap(String id, Map<String, dynamic> data) {
    return Excursion(
      id: id,
      name: data['nome'] ?? '',
      description: data['descricao'] ?? '',
      idMainDestination: data['idDestinoPrincipal'] ?? '',
      startDate: (data['dataPartida'] as Timestamp).toDate(),
      returnDate: (data['dataRetorno'] as Timestamp).toDate(),
      basePrice: (data['precoBase'] as num?)?.toDouble() ?? 0.0,
      totalSeats: data['assentosTotais'] as int? ?? 0,
      reservedSeats: data['assentosReservados'] as int? ?? 0,
      paidSeats: data['assentosPagos'] as int? ?? 0,
      slug: data['slug'] ?? '',
      idResponsible: data['idResponsavel'] ?? '',
      empresa: data['empresa'] ?? '', // Lendo do Firestore
      isDeleted: data['excluido'] ?? false,
      status: _parseStatus(data['status']),
      createdAt: (data['criadoEm'] as Timestamp?)?.toDate(),
      updatedAt: (data['atualizadoEm'] as Timestamp?)?.toDate(),
    );
  }

  static String _statusToString(ExcursionStatus status) {
    switch (status) {
      case ExcursionStatus.programada: return 'PROGRAMADA';
      case ExcursionStatus.emAndamento: return 'EM_ANDAMENTO';
      case ExcursionStatus.concluida: return 'CONCLUIDA';
      case ExcursionStatus.cancelada: return 'CANCELADA';
    }
  }

  static ExcursionStatus _parseStatus(String? status) {
    switch (status) {
      case 'PROGRAMADA': return ExcursionStatus.programada;
      case 'EM_ANDAMENTO': return ExcursionStatus.emAndamento;
      case 'CONCLUIDA': return ExcursionStatus.concluida;
      case 'CANCELADA': return ExcursionStatus.cancelada;
      default: return ExcursionStatus.programada;
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
    int? paidSeats,
    String? slug,
    ExcursionStatus? status,
    String? idResponsible,
    String? empresa, // NOVO no copyWith
    bool? isDeleted,
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
      paidSeats: paidSeats ?? this.paidSeats,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      idResponsible: idResponsible ?? this.idResponsible,
      empresa: empresa ?? this.empresa,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
