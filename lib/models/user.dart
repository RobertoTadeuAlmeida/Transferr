import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String company; // ID da Empresa (Map to 'empresa')
  final String companyName; // Nome Fantasia (Map to 'nomeEmpresa')
  final List<String> companies; // IDs de todas as empresas vinculadas
  final String name; 
  final String email;
  final String phone;
  final String document;
  final String password;
  final DateTime birthDate;
  final String profile; 
  final bool isActive;

  final String zipCode;
  final String address;
  final String number;
  final String neighborhood;
  final String city;
  final String state;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  User({
    required this.id,
    required this.company,
    this.companyName = '',
    this.companies = const [],
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

  bool get isAdmin => profile.toUpperCase() == 'ADMIN';
  bool get isAgente => profile.toUpperCase() == 'AGENTE';

  Map<String, dynamic> toMap() {
    return {
      'empresa': company,
      'nomeEmpresa': companyName,
      'empresas': companies.isEmpty ? [company] : companies,
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

  factory User.fromMap(String id, Map<String, dynamic> map) {
    List<String> companiesList = [];
    if (map['empresas'] != null) {
      companiesList = List<String>.from(map['empresas']);
    } else if (map['empresa'] != null) {
      companiesList = [map['empresa']];
    }

    return User(
      id: id,
      company: map['empresa'] ?? '',
      companyName: map['nomeEmpresa'] ?? '',
      companies: companiesList,
      name: map['nome'] ?? '',
      email: map['email'] ?? '',
      phone: map['telefone'] ?? '',
      document: map['documento'] ?? '',
      password: '',
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

  User copyWith({
    String? id,
    String? company,
    String? companyName,
    List<String>? companies,
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
      companyName: companyName ?? this.companyName,
      companies: companies ?? this.companies,
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
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
