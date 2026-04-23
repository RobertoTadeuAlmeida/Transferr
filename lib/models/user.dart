import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String company; 
  final String companyName;
  final List<String> companies; 
  final Map<String, String> roles; // { "id_empresa": "OWNER", "ADMIN" ou "AGENTE" }
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

  User({
    required this.id,
    required this.company,
    this.companyName = '',
    this.companies = const [],
    this.roles = const {},
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
  });

  // ===========================================================================
  // ----------- GETTERS DE LOGICA MULTI-TENANT -----------
  // ===========================================================================

  /// O papel atual do usuário na empresa que ele está acessando
  String get currentRole => roles[company]?.toUpperCase() ?? 'AGENTE';

  /// ADMIN ou OWNER são considerados administradores
  bool get isAdmin => profile.toUpperCase() == 'ADMIN' || 
                      profile.toUpperCase() == 'OWNER' ||
                      currentRole == 'ADMIN' || 
                      currentRole == 'OWNER';
  
  /// Apenas o OWNER tem a "coroa"
  bool get isOwner => currentRole == 'OWNER';

  bool get isAgente => !isAdmin;

  bool get hasNoCompany => companies.isEmpty && company.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'empresa': company,
      'nomeEmpresa': companyName,
      'empresas': companies,
      'papeis': roles,
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
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      company: map['empresa'] ?? '',
      companyName: map['nomeEmpresa'] ?? '',
      companies: List<String>.from(map['empresas'] ?? []),
      roles: Map<String, String>.from(map['papeis'] ?? {}),
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
    );
  }

  User copyWith({
    String? id,
    String? company,
    String? companyName,
    List<String>? companies,
    Map<String, String>? roles,
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
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      company: company ?? this.company,
      companyName: companyName ?? this.companyName,
      companies: companies ?? this.companies,
      roles: roles ?? this.roles,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
