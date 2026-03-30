import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transferr/models/user.dart';

void main() {
  group('User Model Tests', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final mockUserData = {
      'empresa': 'empresa_123',
      'nomeEmpresa': 'Agência Sol',
      'empresas': ['empresa_123', 'empresa_456'],
      'papeis': {
        'empresa_123': 'ADMIN',
        'empresa_456': 'AGENTE',
      },
      'nome': 'João Silva',
      'email': 'joao@email.com',
      'telefone': '11999999999',
      'documento': '12345678900',
      'dataNascimento': timestamp,
      'perfil': 'AGENTE',
      'isActive': true,
      'cep': '01001000',
      'endereco': 'Praça da Sé',
      'numero': '1',
      'bairro': 'Centro',
      'cidade': 'São Paulo',
      'estado': 'SP',
      'criadoEm': timestamp,
    };

    test('should create User from map correctly', () {
      final user = User.fromMap('user_abc', mockUserData);

      expect(user.id, 'user_abc');
      expect(user.name, 'João Silva');
      expect(user.companies, contains('empresa_456'));
      expect(user.roles['empresa_123'], 'ADMIN');
      expect(user.company, 'empresa_123');
    });

    test('isAdmin should return true if user is ADMIN in current company', () {
      final user = User.fromMap('user_abc', mockUserData);
      
      // Ele é AGENTE global, mas ADMIN na empresa_123 (ativa)
      expect(user.isAdmin, isTrue);
    });

    test('isAdmin should return false if user is AGENTE in current company', () {
      final dataWithDifferentActiveCompany = Map<String, dynamic>.from(mockUserData);
      dataWithDifferentActiveCompany['empresa'] = 'empresa_456';
      
      final user = User.fromMap('user_abc', dataWithDifferentActiveCompany);
      
      // Agora a empresa ativa é a 456, onde ele é AGENTE
      expect(user.isAdmin, isFalse);
    });

    test('isAdmin should return true if user profile is ADMIN regardless of company role', () {
      final adminData = Map<String, dynamic>.from(mockUserData);
      adminData['perfil'] = 'ADMIN';
      adminData['papeis'] = {'empresa_123': 'AGENTE'};
      
      final user = User.fromMap('user_abc', adminData);
      
      expect(user.isAdmin, isTrue);
    });

    test('hasNoCompany should return true if companies list is empty', () {
      final user = User(
        id: '1', company: '', name: '', email: '', phone: '', 
        document: '', birthDate: now, zipCode: '', address: '', 
        number: '', neighborhood: '', city: '', state: '', 
        createdAt: now, companies: [], roles: {},
      );

      expect(user.hasNoCompany, isTrue);
    });
  });
}
