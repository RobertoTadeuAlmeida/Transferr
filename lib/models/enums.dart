/// Represents the possible states of an excursion.
enum ExcursionStatus {
  agendada, // agendada
  confirmada, // confirmada
  realizada, // realizada
  cancelada,  // cancelada
}

/// Represents the possible payment states of a participant.
enum PaymentStatus {
  pending,   // pendente
  paid,      // pago
  partial,
  free,   // parcial
}

/// Represents the possible attendance states of a participant.
enum ParticipantStatus {
  pending,    // pendente
  confirmed,  // confirmado
  canceled,   // cancelado
}
