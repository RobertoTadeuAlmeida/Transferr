import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'user_provider.dart';
import 'excursion_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
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

  AuthProvider(this._authService) {
    _init();
  }

  void update(UserProvider userProvider, ExcursionProvider excursionProvider) {
    _userProvider = userProvider;
    _excursionProvider = excursionProvider;
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

  Future<void> refreshUser([String? uid]) async {
    final targetUid = uid ?? _currentUser?.id;
    if (targetUid == null) return;

    try {
      final user = await _authService.getUserData(targetUid);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ AUTH_PROVIDER: Erro ao dar refresh no usuário: $e");
    }
  }

  // RESTAURADO: Método para criar empresa (usado na PendingCompanyPage)
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

  // RESTAURADO: Método para trocar empresa (usado na MyCompanyPage)
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

  // RESTAURADO: Método de registro (usado na RegistrationPage)
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
