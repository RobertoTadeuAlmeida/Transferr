import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _service;
  StreamSubscription? _userSubscription;
  StreamSubscription? _inviteSubscription;

  List<User> _allUsers = [];
  List<User> _filteredUsers = []; 
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = false;
  String? _error;
  String _searchTerm = '';
  String? _currentCompanyId;
  String? _currentInviteUserId;

  UserProvider(this._service);

  List<User> get users => _searchTerm.isEmpty ? _allUsers : _filteredUsers;
  List<Map<String, dynamic>> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get usersCount => users.length;

  void clearData() {
    _userSubscription?.cancel();
    _inviteSubscription?.cancel();
    _userSubscription = null;
    _inviteSubscription = null;
    _allUsers = [];
    _filteredUsers = [];
    _pendingInvites = [];
    _currentCompanyId = null;
    _currentInviteUserId = null;
    _searchTerm = '';
    _error = null;
    notifyListeners();
  }

  void searchUsers(String term) {
    final newTerm = term.trim().toLowerCase();
    if (_searchTerm == newTerm) return; 
    _searchTerm = newTerm;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchTerm.isEmpty) {
      _filteredUsers = [];
    } else {
      _filteredUsers = _allUsers.where((user) {
        return user.name.toLowerCase().contains(_searchTerm) || 
               user.email.toLowerCase().contains(_searchTerm);
      }).toList();
    }
  }

  void initCompanyStream(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      _allUsers = [];
      _currentCompanyId = null;
      _userSubscription?.cancel();
      notifyListeners();
      return;
    }
    
    if (_currentCompanyId == companyId) return;

    _currentCompanyId = companyId;
    _setLoading(true);
    _userSubscription?.cancel();

    _userSubscription = _service.getUsersStream(companyId).listen(
      (userList) {
        _allUsers = userList;
        _applyFilter();
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
    if (_currentInviteUserId == userId) return;
    
    _currentInviteUserId = userId;
    _inviteSubscription?.cancel();
    
    _inviteSubscription = _service.getPendingInvites(userId).listen((invites) {
      if (_pendingInvites.toString() != invites.toString()) {
        _pendingInvites = invites;
        notifyListeners();
      }
    });
  }

  // ===========================================================================
  // GESTÃO DE EQUIPE (Ações de Admin/Owner)
  // ===========================================================================

  /// Altera o papel de um membro (Agente <-> Admin).
  Future<void> updateMemberRole({
    required User operator,
    required String targetUserId,
    required String companyId,
    required String newRole,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.updateMemberRole(
        operator: operator,
        targetUserId: targetUserId,
        companyId: companyId,
        newRole: newRole,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove um membro da empresa (Expulsão).
  Future<void> removeMember({
    required User operator,
    required String targetUserId,
    required String companyId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.removeMemberFromCompany(
        operator: operator,
        targetUserId: targetUserId,
        companyId: companyId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Passa a titularidade da empresa para outro usuário.
  Future<void> transferOwnership({
    required User currentOwner,
    required String targetUserId,
    required String companyId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _service.transferOwnership(
        currentOwner: currentOwner,
        targetUserId: targetUserId,
        companyId: companyId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // CONVITES E CADASTRO
  // ===========================================================================

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
    if (_isLoading == value) return; 
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
