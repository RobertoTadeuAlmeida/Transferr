import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserService _service;
  StreamSubscription? _userSubscription;
  StreamSubscription? _inviteSubscription;

  List<User> _allUsers = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = false;
  String? _error;
  String _searchTerm = '';
  String? _currentCompanyId;
  String? _currentInviteUserId; // PERFORMANCE: Cache para evitar re-sub de convites

  UserProvider({UserService? service})
      : _service = service ?? UserService(UserRepository());

  List<User> get users {
    if (_searchTerm.isEmpty) return _allUsers;
    
    // PERFORMANCE: Cache do termo em lowercase para evitar processamento repetitivo no loop
    final term = _searchTerm.toLowerCase();
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(term) || 
             user.email.toLowerCase().contains(term);
    }).toList();
  }

  List<Map<String, dynamic>> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get usersCount => users.length;

  void searchUsers(String term) {
    final newTerm = term.trim();
    if (_searchTerm == newTerm) return; // Só notifica se mudar
    _searchTerm = newTerm;
    notifyListeners();
  }

  void initCompanyStream(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      _allUsers = [];
      _currentCompanyId = null;
      _userSubscription?.cancel();
      notifyListeners();
      return;
    }
    
    // PERFORMANCE: Impede que o Stream reinicie se já estivermos na mesma empresa
    if (_currentCompanyId == companyId) return;

    _currentCompanyId = companyId;
    _isLoading = true;
    _userSubscription?.cancel();

    _userSubscription = _service.getUsersStream(companyId).listen(
      (userList) {
        _allUsers = userList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = 'Erro ao sincronizar equipe.';
        notifyListeners();
      },
    );
  }

  void initInviteStream(String userId) {
    if (userId.isEmpty) return;
    
    // PERFORMANCE: Impede que o Stream reinicie se o usuário logado for o mesmo
    if (_currentInviteUserId == userId) return;
    
    _currentInviteUserId = userId;
    _inviteSubscription?.cancel();
    
    _inviteSubscription = _service.getPendingInvites(userId).listen((invites) {
      // PERFORMANCE: Só notifica se a quantidade de convites mudou 
      // ou se os dados são diferentes (evita rebuilds infinitos em loops de build)
      if (_pendingInvites.length != invites.length) {
        _pendingInvites = invites;
        notifyListeners();
      }
    });
  }

  Future<User?> findUserByEmail(String email) => _service.findUserByEmail(email);

  Future<void> sendInvite({
    required String fromCompanyId,
    required String fromCompanyName,
    required String toUserEmail,
    required String currentUserId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.sendInvite(
        fromCompanyId: fromCompanyId,
        fromCompanyName: fromCompanyName,
        toUserEmail: toUserEmail,
        currentUserId: currentUserId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> respondToInvite({
    required String inviteId,
    required String status,
    required User currentUser,
    required String companyId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.respondToInvite(
        inviteId: inviteId,
        status: status,
        currentUser: currentUser,
        companyId: companyId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveUser(User user) async {
    _setLoading(true);
    try {
      await _service.saveUserData(user);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    await _service.toggleUserStatus(userId, !currentStatus);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return; // Evita notificações redundantes
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _inviteSubscription?.cancel();
    super.dispose();
  }
}
