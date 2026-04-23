import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/services/auth_service.dart';

import '../services/auth_service_test.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUserProvider extends Mock implements UserProvider {}
class MockExcursionProvider extends Mock implements ExcursionProvider {}
class FakeUser extends Fake implements User {}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;
  late MockUserProvider mockUserProvider;
  late MockExcursionProvider mockExcursionProvider;
  // CORREÇÃO: Tipando o StreamController corretamente
  late StreamController<fb_auth.User?> authStreamController;
  late MockUserService mockUserService;


  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserProvider = MockUserProvider();
    mockExcursionProvider = MockExcursionProvider();
    // CORREÇÃO: Inicializando com o tipo correto
    authStreamController = StreamController<fb_auth.User?>.broadcast();
    mockUserService = MockUserService();

    // Agora o Mocktail reconhecerá que o Stream retornado é compatível com User?
    when(() => mockAuthService.authStateChanges).thenAnswer((_) => authStreamController.stream);
    when(() => mockAuthService.logout()).thenAnswer((_) async => {});

    authProvider = AuthProvider(mockAuthService, mockUserService);
    authProvider.update(mockUserProvider, mockExcursionProvider);
  });

  tearDown(() {
    authStreamController.close();
  });

  final tUser = User(
    id: 'user_123',
    name: 'João Motorista',
    email: 'joao@transferr.com',
    phone: '11999999999',
    document: '12345678900',
    birthDate: DateTime(1990, 1, 1),
    zipCode: '01001000',
    address: 'Rua das Flores',
    number: '123',
    neighborhood: 'Centro',
    city: 'São Paulo',
    state: 'SP',
    company: 'emp_1',
    companyName: 'Transferr Brasil',
    companies: ['emp_1'],
    roles: {'emp_1': 'OWNER'},
    profile: 'OWNER',
    isActive: true,
    createdAt: DateTime.now(),
  );

  group('AuthProvider - Getters e Estado Inicial', () {
    test('Deve iniciar com estado limpo e hasNoCompany true', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.hasNoCompany, isTrue);
    });

    test('Deve retornar corretamente os níveis de acesso (Owner/Admin)', () async {
      when(() => mockAuthService.getUserData(any())).thenAnswer((_) async => tUser);
      
      await authProvider.refreshUser('user_123');

      expect(authProvider.isOwner, isTrue);
      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.isAgente, isFalse);
    });
  });

  group('AuthProvider - Segurança (Logout Forçado)', () {
    test('Deve deslogar automaticamente se o usuário for desativado (isActive = false)', () async {
      final userInativo = tUser.copyWith(isActive: false);
      when(() => mockAuthService.getUserData(any())).thenAnswer((_) async => userInativo);
      when(() => mockUserProvider.clearData()).thenReturn(null);
      when(() => mockExcursionProvider.clearData()).thenReturn(null);

      await authProvider.refreshUser('user_123');

      verify(() => mockAuthService.logout()).called(1);
      verify(() => mockUserProvider.clearData()).called(1);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.errorMessage, contains('desativada'));
    });
  });

  group('AuthProvider - Gestão Multi-tenant', () {
    test('switchCompany deve atualizar o usuário e notificar listeners', () async {
      when(() => mockAuthService.switchActiveCompany(any(), any())).thenAnswer((_) async => {});
      when(() => mockAuthService.getUserData(any())).thenAnswer((_) async => tUser);

      await authProvider.refreshUser('user_123');
      await authProvider.switchCompany('emp_2');

      verify(() => mockAuthService.switchActiveCompany('user_123', 'emp_2')).called(1);
      verify(() => mockAuthService.getUserData('user_123')).called(2);
    });

    test('transferOwnership deve delegar para o serviço e dar refresh', () async {
      when(() => mockAuthService.transferOwnership(any(), any(), any())).thenAnswer((_) async => {});
      when(() => mockAuthService.getUserData(any())).thenAnswer((_) async => tUser);
      
      await authProvider.refreshUser('user_123');
      await authProvider.transferOwnership('alvo_id', 'emp_1');

      verify(() => mockAuthService.transferOwnership(any(), 'alvo_id', 'emp_1')).called(1);
    });
  });

  group('AuthProvider - Core Auth', () {
    test('login deve gerenciar loading e capturar erros como string', () async {
      when(() => mockAuthService.login(any(), any())).thenThrow('Credenciais inválidas');

      try {
        await authProvider.login('test@email.com', '123');
      } catch (_) {}

      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, 'Credenciais inválidas');
    });

    test('logout deve limpar todos os providers dependentes', () async {
      when(() => mockUserProvider.clearData()).thenReturn(null);
      when(() => mockExcursionProvider.clearData()).thenReturn(null);

      await authProvider.logout();

      verify(() => mockUserProvider.clearData()).called(1);
      verify(() => mockExcursionProvider.clearData()).called(1);
      verify(() => mockAuthService.logout()).called(1);
    });
  });
}
