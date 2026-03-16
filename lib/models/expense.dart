import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String description;
  final double value;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.value,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'descricao': description,
      'valor': value,
      'categoria': category,
      'data': Timestamp.fromDate(date),
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      description: data['descricao'] ?? '',
      value: (data['valor'] as num?)?.toDouble() ?? 0.0,
      category: data['categoria'] ?? 'Outros',
      date: (data['data'] as Timestamp).toDate(),
    );
  }
}