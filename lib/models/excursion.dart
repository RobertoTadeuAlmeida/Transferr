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
    this.status = ExcursionStatus.emAndamento,
    required this.idResponsible,
    this.createdAt,
    this.updatedAt,
  });

  // ===========================================================================
  // ----------- LÓGICA DE NEGÓCIO (CÁLCULOS LOCAIS / DDD) -----------
  // ===========================================================================


  /// Verifica se a excursão já atingiu o limite de vagas
  bool get isFull => reservedSeats > totalSeats;

  /// FATURAMENTO MÁXIMO POSSÍVEL:
  /// O valor total que a empresa ganharia se vendesse 100% dos assentos.
  double get faturamentoPrevisto => totalSeats * basePrice;

  /// FATURAMENTO ESTIMADO ATUAL:
  /// Baseado apenas no número de reservas (sem considerar pagamentos parciais).
  double get faturamentoEstimadoAtual => reservedSeats * basePrice;

  /// CUSTO UNITÁRIO POR ASSENTO:
  /// Pega o total de gastos (Ônibus, etc) e divide pela capacidade total.
  /// Ajuda a definir se o precoBase está cobrindo os custos.
  double calcularCustoPorAssento(double totalDespesas) {
    if (totalSeats <= 0) return 0.0;
    return totalDespesas / totalSeats;
  }

  /// LUCRO LÍQUIDO PREVISTO (FINAL):
  /// Quanto sobrará no bolso se todos os assentos forem vendidos.
  double calcularLucroPrevisto(double totalDespesas) {
    return faturamentoPrevisto - totalDespesas;
  }

  /// LUCRO REALIZADO ATUAL (FLUXO DE CAIXA):
  /// Dinheiro que de fato entrou dos passageiros menos as despesas cadastradas.
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
      'status': status.name.toUpperCase(),
      'idResponsavel': idResponsible,
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
    int? paidSeats,
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
      paidSeats: paidSeats ?? this.paidSeats,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      idResponsible: idResponsible ?? this.idResponsible,
    );
  }
}