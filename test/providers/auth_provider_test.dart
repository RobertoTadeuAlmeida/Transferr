import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/providers/auth_provider.dart';
import 'package:transferr/providers/user_provider.dart';
import 'package:transferr/providers/excursion_provider.dart';
import 'package:transferr/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUserProvider extends Mock implements UserProvider {}
class MockExcursionProvider extends Mock implements ExcursionProvider {}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;
  late MockUserProvider mockUserProvider;
  late MockExcursionProvider mockExcursionProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserProvider = MockUserProvider();
    mockExcursionProvider = MockExcursionProvider();

    // Simulação do Stream de Auth do Firebase
    when(() => mockAuthService.authStateChanges).thenAnswer((_) => const Stream.empty());

    authProvider = AuthProvider(mockAuthService);
    
    // Injeta os mocks via update (como o ProxyProvider faz)
    authProvider.update(mockUserProvider, mockExcursionProvider);
  });

  group('AuthProvider Tests', () {
    test('initial state should be clean', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('login should set loading and handle errors', () async {
      when(() => mockAuthService.login(any(), any()))
          .thenThrow(Exception('Senha incorreta'));

      expect(authProvider.isLoading, isFalse);
      
      try {
        await authProvider.login('test@email.com', '123');
      } catch (_) {}

      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, contains('Senha incorreta'));
    });

    test('logout should clear other providers data', () async {
      // ARRANGE
      when(() => mockAuthService.logout()).thenAnswer((_) async => {});
      when(() => mockUserProvider.clearData()).thenReturn(null);
      when(() => mockExcursionProvider.clearData()).thenReturn(null);

      // ACT
      await authProvider.logout();

      // ASSERT
      verify(() => mockUserProvider.clearData()).called(1);
      verify(() => mockExcursionProvider.clearData()).called(1);
      verify(() => mockAuthService.logout()).called(1);
      expect(authProvider.currentUser, isNull);
    });
  });
}
