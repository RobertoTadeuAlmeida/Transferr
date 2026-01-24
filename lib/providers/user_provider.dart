import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  // Injeção do repositório
  final UserRepository _repository = UserRepository();

  // Inscrição para a stream
  StreamSubscription? _userSubscription;

  // Estado Interno
  List<User> _allUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';

  // --- GETTERS ---

  /// Retorna a lista filtrada baseada no termo de busca
  List<User> get users {
    if (_searchTerm.isEmpty) return _allUsers;

    final term = _searchTerm.toLowerCase();
    return _allUsers.where((user) {
      final nameMatches = user.name.toLowerCase().contains(term);
      final emailMatches = user.email.toLowerCase().contains(term);

      // Limpeza de CPF para busca numérica pura
      final cpfClean = (user.document ?? '').replaceAll(RegExp(r'\D'), '');
      final cpfMatches = cpfClean.contains(term);

      return nameMatches || emailMatches || cpfMatches;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get usersCount => users.length;

  // --- CONSTRUTOR ---

  UserProvider() {
    _initUserStream();
  }

  // --- MÉTODOS DE ESTADO ---

  /// Inicia a escuta em tempo real através do repositório
  void _initUserStream() {
    _isLoading = true;
    _userSubscription?.cancel();

    _userSubscription = _repository.getUsersStream().listen(
          (userList) {
        _allUsers = userList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = 'Erro ao sincronizar usuários.';
        notifyListeners();
      },
    );
  }

  /// Atualiza o termo de busca e notifica a UI
  void searchUsers(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  // --- OPERAÇÕES (ENCAMINHAMENTO PARA REPOSITÓRIO) ---

  /// Adiciona ou atualiza um usuário completo
  Future<void> saveUser(User user) async {
    try {
      await _repository.saveUser(user);
    } catch (e) {
      rethrow;
    }
  }

  /// Alterna o status ativo/inativo (Soft Delete)
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _repository.toggleUserStatus(userId, !currentStatus);
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza apenas o cargo do usuário
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _repository.updateUserRole(userId, role);
    } catch (e) {
      rethrow;
    }
  }

  /// Busca um usuário na lista local (síncrono)
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