import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String company; // Map to 'empresa'
  final String name; // Map to 'nome'
  final String email;
  final String phone; // Map to 'telefone'
  final String document; // Map to 'documento' (CPF/CNPJ)
  final String password; // Apenas para transporte temporário, não salvar no banco
  final DateTime birthDate; // Map to 'dataNascimento'
  final String profile; // Map to 'perfil' (ADMIN/AGENTE)
  final bool isActive;

  // Address fields
  final String zipCode; // Map to 'cep'
  final String address; // Map to 'endereco'
  final String number; // Map to 'numero'
  final String neighborhood; // Map to 'bairro'
  final String city; // Map to 'cidade'
  final String state; // Map to 'estado'

  // Timestamps
  final DateTime createdAt; // Map to 'criadoEm'
  final DateTime? updatedAt; // Map to 'atualizadoEm'
  final DateTime? deletedAt; // Map to 'deletadoEm'

  User({
    required this.id,
    required this.company,
    required this.name,
    required this.email,
    required this.phone,
    required this.document,
    this.password = '',
    required this.birthDate,
    this.profile = 'AGENTE',
    this.isActive = true,
    required this.zipCode,
    required this.address,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Helper to check permissions
  bool get isAdmin => profile.toUpperCase() == 'ADMIN';
  bool get isAgente => profile.toUpperCase() == 'AGENTE';

  // Converts User object to Firestore Map (Portuguese Keys)
  Map<String, dynamic> toMap() {
    return {
      'empresa': company,
      'nome': name,
      'email': email,
      'telefone': phone,
      'documento': document,
      'dataNascimento': Timestamp.fromDate(birthDate),
      'perfil': profile.toUpperCase(),
      'isActive': isActive,
      'cep': zipCode,
      'endereco': address,
      'numero': number,
      'bairro': neighborhood,
      'cidade': city,
      'estado': state,
      'criadoEm': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'atualizadoEm': Timestamp.fromDate(updatedAt!),
      if (deletedAt != null) 'deletadoEm': Timestamp.fromDate(deletedAt!),
    };
  }

  // NOVO: Factory para criar User a partir de um Map (usado pelos Repositories)
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      company: map['empresa'] ?? '',
      name: map['nome'] ?? '',
      email: map['email'] ?? '',
      phone: map['telefone'] ?? '',
      document: map['documento'] ?? '',
      password: '', // Senha nunca é trafegada via Map/Banco
      birthDate: (map['dataNascimento'] as Timestamp? ?? Timestamp.now()).toDate(),
      profile: map['perfil'] ?? 'AGENTE',
      isActive: map['isActive'] ?? true,
      zipCode: map['cep'] ?? '',
      address: map['endereco'] ?? '',
      number: map['numero'] ?? '',
      neighborhood: map['bairro'] ?? '',
      city: map['cidade'] ?? '',
      state: map['estado'] ?? '',
      createdAt: (map['criadoEm'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (map['atualizadoEm'] as Timestamp?)?.toDate(),
      deletedAt: (map['deletadoEm'] as Timestamp?)?.toDate(),
    );
  }

  // Factory simplificada que reutiliza o fromMap
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User data for ${doc.id} not found!');
    }
    return User.fromMap(doc.id, data);
  }

  User copyWith({
    String? id,
    String? company,
    String? name,
    String? email,
    String? phone,
    String? document,
    String? password,
    DateTime? birthDate,
    String? profile,
    bool? isActive,
    String? zipCode,
    String? address,
    String? number,
    String? neighborhood,
    String? city,
    String? state,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return User(
      id: id ?? this.id,
      company: company ?? this.company,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      document: document ?? this.document,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      profile: profile ?? this.profile,
      isActive: isActive ?? this.isActive,
      zipCode: zipCode ?? this.zipCode,
      address: address ?? this.address,
      number: number ?? this.number,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}