import 'package:flutter/material.dart';

/// Papéis de acesso do sistema
enum UserRole { 
  admin('ADMIN'), 
  agente('AGENTE');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? role) {
    return UserRole.values.firstWhere(
      (e) => e.value == (role ?? '').toUpperCase(),
      orElse: () => UserRole.agente,
    );
  }
}

/// Status da Excursão com metadados integrados
enum ExcursionStatus {
  programada('PROGRAMADA', 'Programada', Colors.blue, Icons.event_note),
  emAndamento('EM_ANDAMENTO', 'Em Andamento', Colors.orange, Icons.directions_bus),
  concluida('CONCLUIDA', 'Concluída', Colors.green, Icons.check_circle_outline),
  cancelada('CANCELADA', 'Cancelada', Colors.red, Icons.cancel_outlined);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const ExcursionStatus(this.value, this.label, this.color, this.icon);

  static ExcursionStatus fromString(String? status) {
    return ExcursionStatus.values.firstWhere(
      (e) => e.value == (status ?? '').toUpperCase(),
      orElse: () => ExcursionStatus.programada,
    );
  }
}

/// Status de Pagamento do Passageiro
enum PaymentStatus {
  pendente('PENDENTE', 'Pendente', Colors.orange),
  pago('PAGO', 'Pago', Colors.green),
  parcial('PARCIAL', 'Parcial', Colors.blue),
  cortesia('CORTESIA', 'Cortesia', Colors.purple);

  final String value;
  final String label;
  final Color color;

  const PaymentStatus(this.value, this.label, this.color);

  static PaymentStatus fromString(String? status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == (status ?? '').toUpperCase(),
      orElse: () => PaymentStatus.pendente,
    );
  }
}

/// Status de Embarque (Check-in em tempo real)
enum BoardingStatus {
  aguardando('AGUARDANDO', 'Aguardando', Colors.orange, Icons.access_time_filled),
  embarcou('EMBARCOU', 'Embarcado', Colors.green, Icons.directions_bus),
  parada('PARADA', 'Em Parada', Colors.blue, Icons.coffee),
  desembarcou('DESEMBARCOU', 'Desembarcou', Colors.purple, Icons.location_on),
  naoEmbarcou('NAO_EMBARCOU', 'Faltou', Colors.red, Icons.cancel);

  final String value; // Valor para o Firebase
  final String label; // Texto para UI
  final Color color;  // Cor para UI
  final IconData icon; // Ícone para UI

  const BoardingStatus(this.value, this.label, this.color, this.icon);

  static BoardingStatus fromString(String? status) {
    return BoardingStatus.values.firstWhere(
      (e) => e.value == (status ?? '').toUpperCase(),
      orElse: () => BoardingStatus.aguardando,
    );
  }
}

/// Filtros para a lista de passageiros com labels
enum PassengerFilter {
  todos('Todos'),
  pendentes('Pendentes'),
  confirmados('Confirmados'),
  menores('Menores');

  final String label;
  const PassengerFilter(this.label);
}

/// Filtros para o financeiro
enum FinanceFilter {
  todos('Todos'),
  concluido('Concluído'),
  aberto('Em Aberto');

  final String label;
  const FinanceFilter(this.label);
}
