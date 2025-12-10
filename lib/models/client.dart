import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String contact;
  final String cpf;
  final DateTime birthDate;
  final List<String> confirmedExcursionIds;
  final List<String> pendingExcursionIds;

  Client({
    required this.id,
    required this.name,
    required this.contact,
    required this.cpf,
    required this.birthDate,
    this.confirmedExcursionIds = const [],
    this.pendingExcursionIds = const [],
  });

  // Converte o objeto Client em um formato que o Firestore entende.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'cpf': cpf,
      'birthDate': Timestamp.fromDate(birthDate),
      'confirmedExcursionIds': confirmedExcursionIds,
      'pendingExcursionIds': pendingExcursionIds,
    };
  }

  factory Client.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      contact: data['contact'] ?? '',
      cpf: data['cpf'] ?? '',
      birthDate: (data['birthDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      confirmedExcursionIds: List<String>.from(data['confirmedExcursionIds'] ?? []),
      pendingExcursionIds: List<String>.from(data['pendingExcursionIds'] ?? []),
    );
  }
}
