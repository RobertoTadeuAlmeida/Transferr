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
        final user = await _authService.getUserData(fbUser.uid);
        if (user != null) {
          _currentUser = user;
          // LOGICA DE REPARO: Se o usuário é antigo e não tem o campo 'empresa' gravado corretamente
          // ou se os nomes de campos mudaram, forçamos um salvamento para atualizar o Firestore.
          _checkAndRepairUserData(user);
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Verifica se os dados no banco estão atualizados com o novo padrão (Multi-tenant)
  Future<void> _checkAndRepairUserData(User user) async {
    // Se o usuário logou e o objeto carregado via fromMap (que já tem fallback)
    // detectou que os dados originais estavam em campos antigos, salvamos no novo padrão.
    try {
      // Simplesmente salvamos o objeto atual de volta. 
      // O User.toMap() usará 'empresa', 'nome', etc., migrando os dados automaticamente.
      await _authService.saveUserData(user);
      debugPrint("🛡️ AUTH_PROVIDER: Dados do usuário sincronizados/migrados com sucesso.");
    } catch (e) {
      debugPrint("⚠️ AUTH_PROVIDER (Repair): Erro ao atualizar dados legados: $e");
    }
  }

  Future<void> switchCompany(String companyId) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      await _authService.switchActiveCompany(_currentUser!.id, companyId);
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
