import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
// Mantido só para injeção

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  AuthProvider({AuthService? service})
    : _authService = service ?? AuthService(UserRepository()) {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        // Busca os dados completos no Firestore quando o Firebase Auth detectar o login
        _currentUser = await _authService.getUserData(fbUser.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Cadastro
  Future<void> register(User user, String password) async {
    _setLoading(true);
    try {
      await _authService.register(user, password);
    } catch (e) {
      rethrow; // O erro será capturado pela UI
    } finally {
      _setLoading(false);
    }
  }

  /// Login
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.login(email, password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
