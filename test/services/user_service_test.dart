import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/repositories/user_repository.dart';
import 'package:transferr/services/user_service.dart';

class MockUserRepository extends Mock implements UserRepository {}
class FakeUser extends Fake implements User {}

void main() {
  late UserService userService;
  late MockUserRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockRepo = MockUserRepository();
    userService = UserService(mockRepo);
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
    createdAt: DateTime.now(),
  );

  group('UserService - isDocumentUnique', () {
    test('Deve retornar true se o documento não estiver em uso', () async {
      when(() => mockRepo.getUserByDocument('12345678900')).thenAnswer((_) async => null);

      final result = await userService.isDocumentUnique('12345678900', 'user_123');

      expect(result, isTrue);
      verify(() => mockRepo.getUserByDocument('12345678900')).called(1);
    });

    test('Deve retornar true se o documento pertence ao próprio usuário (edição)', () async {
      when(() => mockRepo.getUserByDocument('12345678900')).thenAnswer((_) async => tUser);

      final result = await userService.isDocumentUnique('12345678900', 'user_123');

      expect(result, isTrue);
    });

    test('Deve lançar exceção se o documento já estiver em uso por outro usuário', () async {
      final otherUser = tUser.copyWith(id: 'outro_id');
      when(() => mockRepo.getUserByDocument('12345678900')).thenAnswer((_) async => otherUser);

      await expectLater(
        userService.isDocumentUnique('12345678900', 'user_123'),
        throwsA(isA<String>().having((e) => e, 'mensagem', contains('Documento já cadastrado'))),
      );
    });
  });

  group('UserService - saveUserData', () {
    test('Deve validar o usuário e verificar unicidade do documento antes de salvar', () async {
      when(() => mockRepo.getUserByDocument(any())).thenAnswer((_) async => null);
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.saveUserData(tUser);

      verify(() => mockRepo.getUserByDocument(tUser.document)).called(1);
      verify(() => mockRepo.saveUserData(any())).called(1);
    });

    test('Deve falhar se a validação de integridade do UserValidator falhar', () async {
      final userInvalido = tUser.copyWith(name: ''); // Nome vazio deve disparar erro no validador

      await expectLater(
        userService.saveUserData(userInvalido),
        throwsA(isA<Exception>()),
      );

      verifyNever(() => mockRepo.saveUserData(any()));
    });
  });

  group('UserService - Outras Funcionalidades', () {
    test('Deve sanitizar nome e e-mail ao salvar', () async {
      final userSujo = tUser.copyWith(name: '  João Silva  ', email: 'CONTATO@EMAIL.COM');
      when(() => mockRepo.getUserByDocument(any())).thenAnswer((_) async => null);
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.saveUserData(userSujo);

      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.name, 'nome limpo', 'João Silva')
          .having((u) => u.email, 'email lowercase', 'contato@email.com')
      ))).called(1);
    });

    test('toggleUserStatus deve validar ID antes de chamar repo', () async {
      when(() => mockRepo.toggleUserStatus(any(), any())).thenAnswer((_) async => {});

      await userService.toggleUserStatus('u1', true);
      verify(() => mockRepo.toggleUserStatus('u1', true)).called(1);

      expect(() => userService.toggleUserStatus('', true), throwsA(isA<Exception>()));
    });
  });
}
