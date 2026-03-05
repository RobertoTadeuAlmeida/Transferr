import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../repositories/user_repository.dart'; // Apenas para o default

class UserProvider with ChangeNotifier {
  // Injeção do service
  final UserService _service;

  // Inscrição para a stream (Real-time)
  StreamSubscription? _userSubscription;

  // Estado Interno
  List<User> _allUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';

  // --- CONSTRUTOR ---
  // Permitimos passar o service para facilitar testes unitários no futuro
  UserProvider({UserService? service})
      : _service = service ?? UserService(UserRepository()) {
    _initUserStream();
  }

  // --- GETTERS ---

  /// Retorna a lista filtrada baseada no termo de busca
  List<User> get users {
    if (_searchTerm.isEmpty) return _allUsers;

    final term = _searchTerm.toLowerCase();
    return _allUsers.where((user) {
      final nameMatches = user.name.toLowerCase().contains(term);
      final emailMatches = user.email.toLowerCase().contains(term);

      // Busca pelo documento (CPF) removendo pontuação
      final docClean = user.document.replaceAll(RegExp(r'\D'), '');
      final docMatches = docClean.contains(term);

      return nameMatches || emailMatches || docMatches;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get usersCount => users.length;

  // --- MÉTODOS DE ESTADO ---

  /// Inicia a escuta em tempo real dos usuários do sistema
  void _initUserStream() {
    _isLoading = true;
    _userSubscription?.cancel();

    _userSubscription = _service.getUsersStream().listen(
          (userList) {
        _allUsers = userList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = 'Erro ao sincronizar lista de usuários.';
        notifyListeners();
      },
    );
  }

  /// Atualiza o termo de busca (usado no campo de pesquisa da UI)
  void searchUsers(String term) {
    _searchTerm = term.trim();
    notifyListeners();
  }

  // --- OPERAÇÕES ---

  /// Salva ou atualiza um usuário (usando o UserService)
  Future<void> saveUser(User user) async {
    try {
      await _service.saveUserData(user);
    } catch (e) {
      _error = 'Erro ao salvar usuário.';
      notifyListeners();
      rethrow;
    }
  }

  /// Ativa/Desativa o usuário (Soft Delete)
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _service.toggleUserStatus(userId, !currentStatus);
    } catch (e) {
      _error = 'Erro ao alterar status.';
      notifyListeners();
      rethrow;
    }
  }

  /// Busca um usuário na lista que já está na memória
  User? findLocalUserById(String userId) {
    try {
      return _allUsers.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}