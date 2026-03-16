import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider({AuthService? service})
      : _authService = service ?? AuthService(UserRepository()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        _currentUser = await _authService.getUserData(fbUser.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Troca a empresa ativa do usuário e notifica o sistema
  Future<void> switchCompany(String companyId) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      await _authService.switchActiveCompany(_currentUser!.id, companyId);
      // Atualiza o objeto local para refletir a mudança imediatamente
      _currentUser = _currentUser!.copyWith(company: companyId);
      notifyListeners();
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
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
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
