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
    // Comportamento padrão: documento não existe
    when(() => mockRepo.getUserByDocument(any())).thenAnswer((_) async => null);
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
    createdAt: DateTime.now(),
  );

  group('UserService - Unicidade de Documento', () {
    test('Deve impedir o cadastro se o documento já existir para outro ID', () async {
      // Cenário: Existe um usuário 'OUTRO_ID' com o mesmo documento de 'user_123'
      final existingUser = tUser.copyWith(id: 'OUTRO_ID');
      when(() => mockRepo.getUserByDocument('12345678900')).thenAnswer((_) async => existingUser);

      // Ação: Tentar validar o documento para o novo usuário 'user_123'
      final error = await userService.validateDocumentUniqueness('12345678900', 'user_123');

      // Verificação
      expect(error, equals('Este CPF/CNPJ já está cadastrado em outra conta.'));
    });

    test('Deve permitir se o documento pertencer ao próprio usuário (Update)', () async {
      // Cenário: O usuário está atualizando o perfil, o documento no banco é dele mesmo
      when(() => mockRepo.getUserByDocument('12345678900')).thenAnswer((_) async => tUser);

      // Ação: Valida documento com o ID dele mesmo
      final error = await userService.validateDocumentUniqueness('12345678900', 'user_123');

      // Verificação: Null significa que está liberado
      expect(error, isNull);
    });

    test('saveUserData deve lançar exceção se detectar duplicidade de documento', () async {
      // Cenário: Outro usuário já usa este CPF
      final otherUser = tUser.copyWith(id: 'outro_id');
      when(() => mockRepo.getUserByDocument(any())).thenAnswer((_) async => otherUser);

      // Verificação: Deve estourar a mensagem de erro no save
      expect(() => userService.saveUserData(tUser), 
        throwsA(contains('já está cadastrado em outra conta')));
      
      verifyNever(() => mockRepo.saveUserData(any()));
    });
  });

  group('UserService - Governança OWNER (Coroa)', () {
    test('Não deve permitir que ADMIN rebaixe ou remova o OWNER', () async {
      final admin = tUser.copyWith(id: 'admin', roles: {'emp_1': 'ADMIN'});
      when(() => mockRepo.getUserData(tUser.id)).thenAnswer((_) async => tUser);

      // Falha ao remover
      expect(() => userService.removeMemberFromCompany(operator: admin, targetUserId: tUser.id, companyId: 'emp_1'), 
        throwsA(contains('proprietário da empresa não pode ser removido')));

      // Falha ao rebaixar
      expect(() => userService.updateMemberRole(operator: admin, targetUserId: tUser.id, companyId: 'emp_1', newRole: 'AGENTE'), 
        throwsA(contains('não pode ter seu papel alterado')));
    });

    test('Transferência: Deve trocar coroa e atualizar perfis globais sincronizados', () async {
      final target = tUser.copyWith(id: 'alvo', roles: {'emp_1': 'AGENTE'}, companies: ['emp_1']);
      when(() => mockRepo.getUserData(target.id)).thenAnswer((_) async => target);
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.transferOwnership(currentOwner: tUser, targetUserId: target.id, companyId: 'emp_1');

      // 1. Alvo deve virar OWNER
      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.id, 'id alvo', 'alvo')
          .having((u) => u.roles['emp_1'], 'novo papel', 'OWNER')
          .having((u) => u.profile, 'novo perfil global', 'OWNER')
      ))).called(1);

      // 2. Antigo dono deve virar ADMIN
      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.id, 'id antigo dono', tUser.id)
          .having((u) => u.roles['emp_1'], 'rebaixado papel', 'ADMIN')
          .having((u) => u.profile, 'rebaixado perfil global', 'ADMIN')
      ))).called(1);
    });
  });

  group('UserService - Cenários de Remoção e Contexto', () {
    test('Ao remover membro da empresa ATIVA, deve migrar para próxima disponível', () async {
      final multiCompanyUser = tUser.copyWith(
        id: 'user_multi',
        company: 'emp_1',
        companies: ['emp_1', 'emp_2'],
        roles: {'emp_1': 'AGENTE', 'emp_2': 'ADMIN'},
      );
      
      final operator = tUser;
      when(() => mockRepo.getUserData(multiCompanyUser.id)).thenAnswer((_) async => multiCompanyUser);
      when(() => mockRepo.getCompanyName('emp_2')).thenAnswer((_) async => 'Empresa Secundária');
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.removeMemberFromCompany(operator: operator, targetUserId: multiCompanyUser.id, companyId: 'emp_1');

      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.company, 'migrou contexto', 'emp_2')
          .having((u) => u.companyName, 'migrou nome', 'Empresa Secundária')
          .having((u) => u.companies.length, 'saiu da emp_1', 1)
      ))).called(1);
    });

    test('Ao remover de todas as empresas, deve voltar para Aguardando Vínculo', () async {
      final target = tUser.copyWith(id: 'u_last', company: 'emp_1', companies: ['emp_1'], roles: {'emp_1': 'AGENTE'});
      
      when(() => mockRepo.getUserData(target.id)).thenAnswer((_) async => target);
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.removeMemberFromCompany(operator: tUser, targetUserId: target.id, companyId: 'emp_1');

      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.company, 'contexto vazio', isEmpty)
          .having((u) => u.companyName, 'status inicial', 'Aguardando Vínculo')
      ))).called(1);
    });
  });

  group('UserService - Sistema de Convites', () {
    test('respondToInvite: Aceite deve configurar AGENTE e tornar usuário ativo', () async {
      final newUser = tUser.copyWith(company: '', companies: [], roles: {}, isActive: false);
      when(() => mockRepo.respondToInvite(any(), any())).thenAnswer((_) async => {});
      when(() => mockRepo.saveUserData(any())).thenAnswer((_) async => {});

      await userService.respondToInvite(inviteId: 'i1', status: 'aceito', currentUser: newUser, companyId: 'new_c');

      verify(() => mockRepo.saveUserData(any(
        that: isA<User>()
          .having((u) => u.isActive, 'ativou conta', isTrue)
          .having((u) => u.roles['new_c'], 'papel atribuído', 'AGENTE')
      ))).called(1);
    });
  });
}
