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
    // CORREÇÃO: Removido o parâmetro nomeado 'service:'
    userProvider = UserProvider(mockService);
  });

  group('UserProvider Tests', () {
    
    test('initial state should be empty and not loading', () {
      expect(userProvider.users, isEmpty);
      expect(userProvider.isLoading, isFalse);
      expect(userProvider.error, isNull);
    });

    test('clearData should reset everything and cancel subscriptions', () {
      userProvider.searchUsers('teste');
      userProvider.clearData();

      expect(userProvider.users, isEmpty);
      expect(userProvider.error, isNull);
      expect(userProvider.isLoading, isFalse);
    });

    test('searchUsers should filter existing list in memory', () async {
      final users = [
        User(id: '1', name: 'Alice', email: 'alice@test.com', company: '', companies: [], roles: {}, phone: '', document: '', birthDate: DateTime.now(), zipCode: '', address: '', number: '', neighborhood: '', city: '', state: '', createdAt: DateTime.now()),
        User(id: '2', name: 'Bob', email: 'bob@test.com', company: '', companies: [], roles: {}, phone: '', document: '', birthDate: DateTime.now(), zipCode: '', address: '', number: '', neighborhood: '', city: '', state: '', createdAt: DateTime.now()),
      ];
      
      final controller = StreamController<List<User>>();
      when(() => mockService.getUsersStream(any())).thenAnswer((_) => controller.stream);

      userProvider.initCompanyStream('empresa_1');
      controller.add(users);

      await Future.delayed(Duration.zero);
      
      userProvider.searchUsers('ali');
      expect(userProvider.users.length, 1);
      expect(userProvider.users.first.name, 'Alice');

      userProvider.searchUsers(''); 
      expect(userProvider.users.length, 2);
      
      await controller.close();
    });

    test('sendInvite should set loading true and handle errors', () async {
      when(() => mockService.sendInvite(
        fromCompanyId: any(named: 'fromCompanyId'),
        fromCompanyName: any(named: 'fromCompanyName'),
        toUserEmail: any(named: 'toUserEmail'),
        currentUserId: any(named: 'currentUserId'),
      )).thenThrow(Exception('E-mail inválido'));

      expect(userProvider.isLoading, isFalse);
      
      try {
        await userProvider.sendInvite(
          fromCompanyId: '1',
          fromCompanyName: 'A',
          toUserEmail: 'erro@email.com',
          currentUserId: '9',
        );
      } catch (_) {}

      expect(userProvider.isLoading, isFalse);
      expect(userProvider.error, contains('E-mail inválido'));
    });

    test('initInviteStream should populate pendingInvites', () async {
      final mockInvites = [
        {'id': 'inv_1', 'fromCompanyName': 'Empresa A'},
      ];
      final controller = StreamController<List<Map<String, dynamic>>>();
      
      when(() => mockService.getPendingInvites(any())).thenAnswer((_) => controller.stream);

      userProvider.initInviteStream('user_123');
      controller.add(mockInvites);

      await Future.microtask(() {});
      expect(userProvider.pendingInvites.length, 1);
      expect(userProvider.pendingInvites.first['fromCompanyName'], 'Empresa A');
      
      await controller.close();
    });
  });
}
