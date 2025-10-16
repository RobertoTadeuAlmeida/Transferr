import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  String id; // ID do documento no Firestore
  String name;
  String contact; // Ex: telefone, email
  String cpf;
  DateTime birthDate;
  List<String> confirmedExcursionIds; // IDs das excursões confirmadas
  List<String> pendingExcursionIds; // IDs das excursões pendentes

  Client({
    required this.id,
    required this.name,
    required this.contact,
    required this.cpf,
    required this.birthDate,
    this.confirmedExcursionIds = const [],
    this.pendingExcursionIds = const [],
  });

  // Construtor para criar uma instância de Client a partir de um documento do Firestore
  factory Client.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      contact: data['contact'] ?? '',
      cpf: data['cpf'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      confirmedExcursionIds: List<String>.from(data['confirmedExcursionIds'] ?? []),
      pendingExcursionIds: List<String>.from(data['pendingExcursionIds'] ?? []),
    );
  }

  // Método para converter a instância de Client em um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'contact': contact,
      'cpf': cpf,
      'birthDate': Timestamp.fromDate(birthDate),
      'confirmedExcursionIds': confirmedExcursionIds,
      'pendingExcursionIds': pendingExcursionIds,
    };
  }
}