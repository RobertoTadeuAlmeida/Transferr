import 'package:flutter/material.dart';

/// Papéis de acesso do sistema
enum UserRole { admin, agente }

/// Status da Excursão com metadados integrados
enum ExcursionStatus {
  programada('Programada', Colors.blue, Icons.event_note),
  emAndamento('Em Andamento', Colors.orange, Icons.directions_bus),
  concluida('Concluída', Colors.green, Icons.check_circle_outline),
  cancelada('Cancelada', Colors.red, Icons.cancel_outlined);

  final String label;
  final Color color;
  final IconData icon;

  const ExcursionStatus(this.label, this.color, this.icon);
}

/// Status de Pagamento do Passageiro
enum PaymentStatus {
  pendente('Pendente', Colors.orange),
  pago('Pago', Colors.green),
  parcial('Parcial', Colors.blue),
  cortesia('Cortesia', Colors.purple);

  final String label;
  final Color color;

  const PaymentStatus(this.label, this.color);
}

/// Status de Embarque (Check-in em tempo real)
enum BoardingStatus {
  aguardando('AGUARDANDO', 'Aguardando', Colors.orange, Icons.access_time_filled),
  embarcou('EMBARCOU', 'Embarcado', Colors.green, Icons.directions_bus),
  parada('PARADA', 'Em Parada', Colors.blue, Icons.coffee), // Útil para conferência em postos
  desembarcou('DESEMBARCOU', 'Desembarcou', Colors.purple, Icons.location_on),
  naoEmbarcou('NAO_EMBARCOU', 'Faltou', Colors.red, Icons.cancel);

  final String value; // Valor para o Firebase
  final String label; // Texto para UI
  final Color color;  // Cor para UI
  final IconData icon; // Ícone para UI

  const BoardingStatus(this.value, this.label, this.color, this.icon);

  /// Converte a String do Firebase de volta para o Enum
  static BoardingStatus fromString(String? status) {
    return BoardingStatus.values.firstWhere(
          (e) => e.value == status,
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