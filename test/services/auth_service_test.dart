import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/repositories/user_repository.dart';
import 'package:transferr/services/auth_service.dart';
import 'package:transferr/services/user_service.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockUserService extends Mock implements UserService {}
class MockUserCredential extends Mock implements fb_auth.UserCredential {}
class MockFbUser extends Mock implements fb_auth.User {}
class FakeUser extends Fake implements User {}

void main() {
  late AuthService authService;
  late MockUserRepository mockUserRepo;
  late MockUserService mockUserService;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockUserService = MockUserService();
    authService = AuthService(mockUserRepo, mockUserService);
  });

  final tUser = User(
    id: 'user_123',
    name: 'João Teste',
    email: 'joao@test.com',
    phone: '11999999999',
    document: '12345678900',
    birthDate: DateTime(1990, 1, 1),
    zipCode: '01001000',
    address: 'Rua A',
    number: '123',
    neighborhood: 'Centro',
    city: 'SP',
    state: 'SP',
    company: 'emp_1',
    companyName: 'Agência Teste',
    companies: ['emp_1'],
    roles: {'emp_1': 'ADMIN'},
    profile: 'ADMIN',
    isActive: true,
    createdAt: DateTime.now(),
  );

  group('AuthService - login', () {
    late MockUserCredential mockCredential;
    late MockFbUser mockFbUser;

    setUp(() {
      mockCredential = MockUserCredential();
      mockFbUser = MockFbUser();
      when(() => mockFbUser.uid).thenReturn('user_123');
      when(() => mockCredential.user).thenReturn(mockFbUser);
      when(() => mockUserRepo.signIn(any(), any())).thenAnswer((_) async => mockCredential);
      when(() => mockUserRepo.signOut()).thenAnswer((_) async => {});
    });

    test('Deve falhar se e-mail ou senha forem vazios', () async {
      await expectLater(authService.login('', '123'), throwsA('E-mail e senha são obrigatórios.'));
    });

    test('Deve realizar login com sucesso para usuário ativo', () async {
      when(() => mockUserRepo.getUserData('user_123')).thenAnswer((_) async => tUser);
      await authService.login('joao@test.com', 'pass123');
      verify(() => mockUserRepo.signIn('joao@test.com', 'pass123')).called(1);
    });

    test('Deve barrar e deslogar se a conta estiver desativada', () async {
      final inativo = tUser.copyWith(isActive: false);
      when(() => mockUserRepo.getUserData('user_123')).thenAnswer((_) async => inativo);

      await expectLater(
        authService.login('joao@test.com', 'pass123'),
        throwsA(contains('Sua conta global está desativada')),
      );
      verify(() => mockUserRepo.signOut()).called(1);
    });
  });

  group('AuthService - register', () {
    late MockUserCredential mockCredential;
    late MockFbUser mockFbUser;

    setUp(() {
      mockCredential = MockUserCredential();
      mockFbUser = MockFbUser();
      when(() => mockFbUser.uid).thenReturn('NEW_UID');
      when(() => mockCredential.user).thenReturn(mockFbUser);
      when(() => mockFbUser.updateDisplayName(any())).thenAnswer((_) async => {});
      when(() => mockUserRepo.signUp(any(), any())).thenAnswer((_) async => mockCredential);
      // null significa que o documento é único (sucesso na validação)
      when(() => mockUserService.validateDocumentUniqueness(any(), any())).thenAnswer((_) async => null);
      when(() => mockUserService.saveUserData(any())).thenAnswer((_) async => {});
    });

    test('Deve interromper registro se o documento já existir', () async {
      when(() => mockUserService.validateDocumentUniqueness(any(), any())).thenAnswer((_) async => 'Doc Duplicado');
      await expectLater(authService.register(tUser, '123'), throwsA('Doc Duplicado'));
      verifyNever(() => mockUserRepo.signUp(any(), any()));
    });

    test('Configuração OWNER: Deve criar empresa própria no registro', () async {
      final input = tUser.copyWith(id: '', company: 'Minha Agência');
      await authService.register(input, '123');

      verify(() => mockUserService.saveUserData(any(
        that: isA<User>()
          .having((u) => u.company, 'id empresa', 'NEW_UID')
          .having((u) => u.companyName, 'nome', 'Minha Agência')
          .having((u) => u.profile, 'perfil', 'OWNER')
      ))).called(1);
    });

    test('Rollback: Deve deletar no Auth se falhar no Firestore', () async {
      when(() => mockUserService.saveUserData(any())).thenThrow('Erro Firestore');
      when(() => mockUserRepo.deleteAuthUser(any())).thenAnswer((_) async => {});

      await expectLater(authService.register(tUser, '123'), throwsA('Erro Firestore'));
      verify(() => mockUserRepo.deleteAuthUser(mockFbUser)).called(1);
    });
  });

  group('AuthService - Multi-tenant Utils', () {
    test('createOwnCompany: Deve configurar usuário como OWNER', () async {
      when(() => mockUserService.saveUserData(any())).thenAnswer((_) async => {});
      await authService.createOwnCompany(tUser, 'Nova Agência');

      verify(() => mockUserService.saveUserData(any(
        that: isA<User>()
          .having((u) => u.profile, 'profile', 'OWNER')
          .having((u) => u.companyName, 'name', 'Nova Agência')
          .having((u) => u.roles['user_123'], 'role map', 'OWNER')
      ))).called(1);
    });

    test('switchActiveCompany: Deve atualizar campos company e companyName', () async {
      when(() => mockUserRepo.updateUserData(any(), any())).thenAnswer((_) async => {});
      when(() => mockUserRepo.getCompanyName(any())).thenAnswer((_) async => 'Agência X');

      await authService.switchActiveCompany('u1', 'comp_x');

      verify(() => mockUserRepo.updateUserData('u1', {
        'company': 'comp_x',
        'companyName': 'Agência X',
      })).called(1);
    });
  });
}
