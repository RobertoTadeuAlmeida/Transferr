import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'enums.dart';

/// Enum para gerenciar os estados de embarque de forma tipada

class Passenger {
  final String id;
  final String excursionId;
  final String name;
  final String document;
  final String phone;
  final DateTime birthDate;
  final String seatNumber;
  final bool isMinor;
  final double depositValue;
  final int totalTrips;


  // Controle de Embarque
  final BoardingStatus statusEmbarque;
  final String? agenteResponsavel;

  // Dados do Responsável (Encapsulados)
  final Guardian? guardian;

  Passenger({
    required this.id,
    required this.excursionId,
    required this.name,
    required this.document,
    required this.phone,
    required this.birthDate,
    required this.seatNumber,
    required this.isMinor,
    this.statusEmbarque = BoardingStatus.aguardando,
    this.agenteResponsavel,
    this.guardian,
    this.depositValue = 0.0,
    this.totalTrips = 0,
  });

  // --- GETTERS DE NEGÓCIO ---

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

  // --- MAPEAR PARA/DO FIREBASE ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': name,
      'documento': document,
      'telefone': phone,
      'nascimento': Timestamp.fromDate(birthDate),
      'poltrona': seatNumber,
      'ehMenor': isMinor,
      'statusEmbarque': statusEmbarque.value,
      'agenteResponsavel': agenteResponsavel,
      'responsavel': isMinor ? guardian?.toMap() : null,
      'atualizadoEm': FieldValue.serverTimestamp(),
      'valorDeposito': depositValue,
      'totalViagens': totalTrips,
    };
  }

  factory Passenger.fromMap(String id, Map<String, dynamic> map) {
    return Passenger(
      id: id,
      excursionId: '',
      name: map['nome'] ?? '',
      document: map['documento'] ?? '',
      phone: map['telefone'] ?? '',
      birthDate: (map['nascimento'] as Timestamp).toDate(),
      seatNumber: map['poltrona'] ?? '',
      isMinor: map['ehMenor'] ?? false,
      statusEmbarque: BoardingStatus.fromString(map['statusEmbarque']),
      agenteResponsavel: map['agenteResponsavel'],
      guardian: map['responsavel'] != null
          ? Guardian.fromMap(map['responsavel'])
          : null,
      depositValue: (map['depositValue'] ?? 0.0).toDouble(),
      totalTrips: (map['totalViagens'] ?? 0).toInt(),

    );
  }

  // --- IMUTABILIDADE (COPYWITH) ---

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
    Guardian? guardian,
    double? depositValue,
    int? totalTrips,
  }) {
    return Passenger(
      id: this.id,
      excursionId: this.excursionId,
      name: name ?? this.name,
      document: document ?? this.document,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      seatNumber: seatNumber ?? this.seatNumber,
      isMinor: isMinor ?? this.isMinor,
      statusEmbarque: statusEmbarque ?? this.statusEmbarque,
      agenteResponsavel: agenteResponsavel ?? this.agenteResponsavel,
      guardian: guardian ?? this.guardian,
      depositValue: depositValue ?? this.depositValue,
      totalTrips: totalTrips ?? this.totalTrips,
    );
  }
}

/// Classe auxiliar para dados do Responsável
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
