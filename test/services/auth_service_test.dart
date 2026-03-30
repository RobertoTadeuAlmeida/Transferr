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
      await authService.login('joao@transferr.com', 'pass123');
      verify(() => mockUserRepo.signIn('joao@transferr.com', 'pass123')).called(1);
    });

    test('Deve permitir login para usuário sem empresa (desvinculado)', () async {
      final semEmpresa = tUser.copyWith(company: '', companies: [], companyName: 'Aguardando Vínculo');
      when(() => mockUserRepo.getUserData('user_123')).thenAnswer((_) async => semEmpresa);

      await authService.login('joao@transferr.com', 'pass123');
      
      verify(() => mockUserRepo.getUserData('user_123')).called(1);
    });

    test('Deve barrar e deslogar se a conta estiver desativada (isActive=false)', () async {
      final inativo = tUser.copyWith(isActive: false);
      when(() => mockUserRepo.getUserData('user_123')).thenAnswer((_) async => inativo);

      await expectLater(
        authService.login('joao@transferr.com', 'pass123'),
        throwsA(contains('Sua conta global está desativada')),
      );
      verify(() => mockUserRepo.signOut()).called(1);
    });

    test('Deve tratar erros do Firebase (ex: senha errada) com mensagens amigáveis', () async {
      when(() => mockUserRepo.signIn(any(), any())).thenThrow(
        fb_auth.FirebaseAuthException(code: 'wrong-password')
      );

      await expectLater(authService.login('j@t.com', '123'), throwsA('Senha incorreta.'));
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
      when(() => mockUserService.isDocumentUnique(any(), any())).thenAnswer((_) async => true);
      when(() => mockUserService.saveUserData(any())).thenAnswer((_) async => {});
    });

    test('Deve interromper registro se o documento já existir', () async {
      when(() => mockUserService.isDocumentUnique(any(), any())).thenThrow('Doc Duplicado');
      await expectLater(authService.register(tUser, '123'), throwsA('Doc Duplicado'));
      verifyNever(() => mockUserRepo.signUp(any(), any()));
    });

    test('Configuração ADMIN: Deve criar empresa própria', () async {
      final input = tUser.copyWith(id: '', profile: 'ADMIN', company: 'Minha Agência');
      await authService.register(input, '123');

      verify(() => mockUserService.saveUserData(any(
        that: isA<User>()
          .having((u) => u.company, 'id empresa', 'NEW_UID')
          .having((u) => u.companyName, 'nome', 'Minha Agência')
      ))).called(1);
    });

    test('Rollback: Deve deletar no Auth se falhar no Firestore', () async {
      when(() => mockUserService.saveUserData(any())).thenThrow('Erro de Rede');
      when(() => mockUserRepo.deleteAuthUser(any())).thenAnswer((_) async => {});

      await expectLater(authService.register(tUser, '123'), throwsA('Erro de Rede'));
      verify(() => mockUserRepo.deleteAuthUser(mockFbUser)).called(1);
    });
  });

  group('AuthService - Utilitários', () {
    test('createOwnCompany: Não deve permitir duplicidade na lista de empresas', () async {
      when(() => mockUserService.saveUserData(any())).thenAnswer((_) async => {});
      final userJaComID = tUser.copyWith(companies: [tUser.id]);

      await authService.createOwnCompany(userJaComID, 'Agência');

      verify(() => mockUserService.saveUserData(any(
        that: isA<User>().having((u) => u.companies.length, 'unicidade', 1)
      ))).called(1);
    });

    test('switchActiveCompany: Deve atualizar para Sem Empresa se ID for vazio', () async {
      when(() => mockUserRepo.updateUserData(any(), any())).thenAnswer((_) async => {});
      await authService.switchActiveCompany('u1', '');
      verify(() => mockUserRepo.updateUserData('u1', {'empresa': '', 'nomeEmpresa': 'Sem Empresa'})).called(1);
    });
  });
}
