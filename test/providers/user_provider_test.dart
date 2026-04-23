import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/services/user_service.dart';

class MockUserService extends Mock implements UserService {}
class FakeUser extends Fake implements User {}

void main() {
  late UserProvider userProvider;
  late MockUserService mockService;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockService = MockUserService();
    userProvider = UserProvider(mockService);
  });

  final tUser = User(
    id: 'u1',
    name: 'João Teste',
    email: 'joao@test.com',
    phone: '11999999999',
    document: '123',
    birthDate: DateTime(1990, 1, 1),
    zipCode: '01001000',
    address: 'Rua A',
    number: '1',
    neighborhood: 'Centro',
    city: 'SP',
    state: 'SP',
    company: 'emp_1',
    companies: ['emp_1'],
    roles: {'emp_1': 'OWNER'},
    profile: 'OWNER',
    createdAt: DateTime.now(),
  );

  group('UserProvider - Streams e Sincronização', () {
    test('initCompanyStream não deve reiniciar se o ID da empresa for o mesmo', () {
      final controller = StreamController<List<User>>();
      when(() => mockService.getUsersStream(any())).thenAnswer((_) => controller.stream);

      userProvider.initCompanyStream('emp_1');
      userProvider.initCompanyStream('emp_1'); // Chamada repetida

      verify(() => mockService.getUsersStream('emp_1')).called(1); 
      controller.close();
    });

    test('initInviteStream deve atualizar a lista de convites reativamente', () async {
      final inviteController = StreamController<List<Map<String, dynamic>>>();
      final tInvites = [{'id': 'inv1', 'fromCompanyName': 'Agência X'}];
      
      when(() => mockService.getPendingInvites(any())).thenAnswer((_) => inviteController.stream);

      userProvider.initInviteStream('u1');
      inviteController.add(tInvites);

      await Future.delayed(Duration.zero);

      expect(userProvider.pendingInvites, tInvites);
      inviteController.close();
    });
  });

  group('UserProvider - Gestão de Equipe (Multi-tenant)', () {
    test('updateMemberRole deve gerenciar loading e erro e limpar erro anterior', () async {
      // Mock para o erro anterior
      when(() => mockService.removeMemberFromCompany(
        operator: any(named: 'operator'),
        targetUserId: any(named: 'targetUserId'),
        companyId: any(named: 'companyId'),
      )).thenAnswer((_) async => throw 'Erro Anterior');

      // CORREÇÃO: Usando thenAnswer com async throw para testar o loading
      when(() => mockService.updateMemberRole(
        operator: any(named: 'operator'),
        targetUserId: any(named: 'targetUserId'),
        companyId: any(named: 'companyId'),
        newRole: any(named: 'newRole'),
      )).thenAnswer((_) async => throw 'Acesso Negado');

      // 1. Forçamos um erro anterior
      try { await userProvider.removeMember(operator: tUser, targetUserId: 'x', companyId: 'y'); } catch (_) {}
      expect(userProvider.error, 'Erro Anterior');
      
      // 2. Disparamos a nova ação
      final call = userProvider.updateMemberRole(
        operator: tUser,
        targetUserId: 'u2',
        companyId: 'emp_1',
        newRole: 'ADMIN',
      );

      expect(userProvider.isLoading, isTrue);
      expect(userProvider.error, isNull); // Deve ter limpado ao iniciar
      
      try { await call; } catch (_) {}

      expect(userProvider.isLoading, isFalse);
      expect(userProvider.error, 'Acesso Negado');
    });

    test('transferOwnership deve delegar para o serviço com sucesso', () async {
      when(() => mockService.transferOwnership(
        currentOwner: any(named: 'currentOwner'),
        targetUserId: any(named: 'targetUserId'),
        companyId: any(named: 'companyId'),
      )).thenAnswer((_) async => {});

      await userProvider.transferOwnership(currentOwner: tUser, targetUserId: 'u2', companyId: 'emp_1');

      verify(() => mockService.transferOwnership(
        currentOwner: tUser,
        targetUserId: 'u2',
        companyId: 'emp_1',
      )).called(1);
    });
  });

  group('UserProvider - Convites e Ações Diretas', () {
    test('sendInvite deve gerenciar fluxo completo', () async {
      when(() => mockService.sendInvite(
        fromCompanyId: any(named: 'fromCompanyId'),
        fromCompanyName: any(named: 'fromCompanyName'),
        toUserEmail: any(named: 'toUserEmail'),
        currentUserId: any(named: 'currentUserId'),
      )).thenAnswer((_) async => {});

      await userProvider.sendInvite(
        fromCompanyId: 'emp_1',
        fromCompanyName: 'Agência',
        toUserEmail: 'alvo@test.com',
        currentUserId: 'u1',
      );

      verify(() => mockService.sendInvite(
        fromCompanyId: 'emp_1',
        fromCompanyName: 'Agência',
        toUserEmail: 'alvo@test.com',
        currentUserId: 'u1',
      )).called(1);
    });

    test('toggleUserStatus deve alternar o status corretamente', () async {
      when(() => mockService.toggleUserStatus(any(), any())).thenAnswer((_) async => {});

      await userProvider.toggleUserStatus('u2', true); // Se atual é true, envia false

      verify(() => mockService.toggleUserStatus('u2', false)).called(1);
    });
  });

  group('UserProvider - Busca e Limpeza', () {
    test('searchUsers deve filtrar a lista corretamente (case-insensitive)', () async {
      final controller = StreamController<List<User>>();
      when(() => mockService.getUsersStream(any())).thenAnswer((_) => controller.stream);
      
      userProvider.initCompanyStream('emp_1');
      controller.add([
        tUser.copyWith(id: '1', name: 'Marcos Silva'),
        tUser.copyWith(id: '2', name: 'Ana Souza'),
      ]);

      await Future.delayed(Duration.zero);
      
      userProvider.searchUsers('SILVA');
      expect(userProvider.users.length, 1);
      expect(userProvider.users.first.name, 'Marcos Silva');
      
      controller.close();
    });

    test('clearData deve resetar completamente o estado e cancelar subscrições', () {
      final userController = StreamController<List<User>>();
      when(() => mockService.getUsersStream(any())).thenAnswer((_) => userController.stream);
      
      userProvider.initCompanyStream('emp_1');
      userProvider.clearData();

      expect(userProvider.users, isEmpty);
      expect(userProvider.pendingInvites, isEmpty);
      expect(userProvider.error, isNull);
      
      userController.close();
    });
  });
}
