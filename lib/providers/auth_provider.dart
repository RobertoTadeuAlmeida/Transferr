import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  User? _currentUser;
  bool _isLoading = true; // Começa como true para o AuthWrapper processar o estado inicial
  String? _errorMessage;
  StreamSubscription<fb.User?>? _authSubscription;

  // --- Getters ---
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  fb.User? get fbUser => _firebaseAuth.currentUser;

  AuthProvider() {
    _initAuthListener();
  }

  /// Monitora mudanças no estado de login do Firebase
  void _initAuthListener() {
    _authSubscription = _firebaseAuth.authStateChanges().listen((fb.User? fbUser) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (fbUser == null) {
        _currentUser = null;
        _isLoading = false; // Finaliza o carregamento se não há usuário
        notifyListeners();
      } else {
        try {
          // Busca o perfil completo no Firestore
          // É aqui que a mágica acontece: vinculamos o Auth ao seu Modelo User
          final userProfile = await _userRepository.getUserById(fbUser.uid);

          if (userProfile == null) {
            _currentUser = null;
            _errorMessage = "Perfil não encontrado no banco de dados.";
          } else {
            _currentUser = userProfile;
            _errorMessage = null;
          }
        } catch (e) {
          debugPrint("Erro ao carregar perfil do usuário: $e");
          _currentUser = null;
          _errorMessage = _parseFirestoreError(e);
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  /// Realiza o login por e-mail e senha
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // O listener (_initAuthListener) reagirá automaticamente ao sucesso do login
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Encerra a sessão
  Future<void> logout() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Limpa o usuário local imediatamente para resposta visual rápida
      _currentUser = null;

      // Desloga do Firebase
      await _firebaseAuth.signOut();

      _errorMessage = null;
    } catch (e) {
      debugPrint("Erro ao sair da conta: $e");
      _errorMessage = "Erro ao sair da conta.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Tratamento de Erros Amigáveis ---

  String _parseAuthError(dynamic e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'E-mail não cadastrado.';
        case 'wrong-password': return 'Senha incorreta.';
        case 'invalid-credential': return 'E-mail ou senha inválidos.'; // Erro comum em novas versões
        case 'user-disabled': return 'Esta conta foi desativada.';
        case 'invalid-email': return 'O e-mail digitado é inválido.';
        case 'too-many-requests': return 'Muitas tentativas. Tente mais tarde.';
        default: return 'Falha na autenticação: ${e.message}';
      }
    }
    return 'Ocorreu um erro inesperado ao entrar.';
  }

  String _parseFirestoreError(dynamic e) {
    final error = e.toString().toLowerCase();
    if (error.contains('permission-denied')) {
      return 'Acesso negado. Verifique as permissões da sua conta.';
    } else if (error.contains('unavailable')) {
      return 'Serviço temporariamente indisponível. Verifique sua internet.';
    }
    return 'Não foi possível carregar seus dados.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}