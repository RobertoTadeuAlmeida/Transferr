import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'user_provider.dart';
import 'excursion_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserService _userService; // Removido final para permitir atualização via update se necessário
  
  StreamSubscription? _authSubscription;
  
  UserProvider? _userProvider;
  ExcursionProvider? _excursionProvider;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isAgente => _currentUser?.isAgente ?? true;
  bool get hasNoCompany => _currentUser?.hasNoCompany ?? true;

  AuthProvider(this._authService, this._userService) {
    _init();
  }

  // Método update agora recebe também o userService se necessário, garantindo que nunca seja nulo
  void update(UserProvider userProvider, ExcursionProvider excursionProvider, {UserService? userService}) {
    _userProvider = userProvider;
    _excursionProvider = excursionProvider;
    if (userService != null) {
      _userService = userService;
    }
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        await refreshUser(fbUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<String?> validateDocument(String document) async {
    _clearError();
    try {
      final error = await _userService.validateDocumentUniqueness(document, _currentUser?.id ?? '');
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
      }
      return error;
    } catch (e) {
      debugPrint("⚠️ AUTH_PROVIDER: Erro ao validar documento: $e");
      return "Erro ao validar documento. Verifique sua conexão.";
    }
  }

  Future<void> refreshUser([String? uid]) async {
    final targetUid = uid ?? _currentUser?.id;
    if (targetUid == null) return;

    try {
      final user = await _authService.getUserData(targetUid);
      
      if (user != null) {
        if (!user.isActive) {
          _errorMessage = "Sua conta foi desativada.";
          await logout();
          return;
        }
        _currentUser = user;
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint("⚠️ AUTH_PROVIDER: Erro ao dar refresh no usuário: $e");
    }
  }

  Future<void> createCompany(String companyName) async {
    if (_currentUser == null) return;
    _clearError();
    _setLoading(true);
    try {
      await _authService.createOwnCompany(_currentUser!, companyName);
      await refreshUser();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> switchCompany(String companyId) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _authService.switchActiveCompany(_currentUser!.id, companyId);
      await refreshUser();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> respondToInvite(String inviteId, String status, String companyId) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _authService.respondToInvite(inviteId, status, _currentUser!, companyId);
      await refreshUser();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> transferOwnership(String targetUserId, String companyId) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _authService.transferOwnership(_currentUser!, targetUserId, companyId);
      await refreshUser();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(User user, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.register(user, password);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.login(email, password);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _userProvider?.clearData();
    _excursionProvider?.clearData();
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
