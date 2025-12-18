import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String contact;
  final String cpf;
  final DateTime birthDate;
  final List<String> confirmedExcursionIds;
  final List<String> pendingExcursionIds;
  final bool isActive;

  Client({
    required this.id,
    required this.name,
    required this.contact,
    required this.cpf,
    required this.birthDate,
    this.confirmedExcursionIds = const [],
    this.pendingExcursionIds = const [],
    this.isActive = false,
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

  factory Client.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // Validação para garantir que os dados do Firestore não estão corrompidos/incompletos.
    if (data == null ||
        data['name'] == null ||
        data['contact'] == null ||
        data['cpf'] == null ||
        data['birthDate'] == null) {
      // Lança um erro claro. Isso ajuda a identificar problemas no seu banco de dados.
      throw StateError(
        'Dados do cliente ${doc.id} estão incompletos ou corrompidos no Firestore!',
      );
    }
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      contact: data['contact'] ?? '',
      cpf: data['cpf'] ?? '',
      birthDate: (data['birthDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      confirmedExcursionIds: List<String>.from(
        data['confirmedExcursionIds'] ?? [],
      ),
      pendingExcursionIds: List<String>.from(data['pendingExcursionIds'] ?? []),
    );
  }

  Client copyWith({
    String? id,
    String? name,
    String? contact,
    String? cpf,
    DateTime? birthDate,
    bool? isActive,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
