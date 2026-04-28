import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';

/// Serviço demo que replica a API usada pela aplicação mas sem depender do Firebase.
class DemoUserService {
  final _uuid = Uuid();
  final List<User> _users = [];
  final StreamController<List<User>> _usersController = StreamController.broadcast();

  DemoUserService() {
    // Seed data
    final now = DateTime.now();
    _users.addAll([
      User(
        id: 'u_admin',
        company: 'c_demo',
        companyName: 'Demo Transportes',
        companies: ['c_demo'],
        roles: {'c_demo': 'OWNER'},
        name: 'Admin Demo',
        email: 'admin@demo.com',
        phone: '999999999',
        document: '00000000000',
        birthDate: now,
        profile: 'OWNER',
        isActive: true,
        zipCode: '',
        address: '',
        number: '',
        neighborhood: '',
        city: '',
        state: '',
        createdAt: now,
      ),
      User(
        id: 'u_user',
        company: 'c_demo',
        companyName: 'Demo Transportes',
        companies: ['c_demo'],
        roles: {'c_demo': 'AGENTE'},
        name: 'Usuário Demo',
        email: 'user@demo.com',
        phone: '988888888',
        document: '11111111111',
        birthDate: now,
        profile: 'AGENTE',
        isActive: true,
        zipCode: '',
        address: '',
        number: '',
        neighborhood: '',
        city: '',
        state: '',
        createdAt: now,
      ),
    ]);

    // initial push
    _emit();
  }

  void _emit() {
    if (!_usersController.isClosed) _usersController.add(List<User>.from(_users));
  }

  Stream<List<User>> getUsersStream(String companyId) {
    final stream = _usersController.stream.map((list) => list.where((u) => u.companies.contains(companyId)).toList());
    // emit current
    Future.microtask(_emit);
    return stream;
  }

  Future<String?> getOwnerUidFromIndex(String indexId) async {
    // simple simulation: if document exists return owner of matching mock
    return _users.firstWhere((u) => u.document.replaceAll(RegExp(r'[^0-9]'), '') == indexId.replaceFirst('doc_', ''), orElse: () => null)?.id;
  }

  Future<String> getCompanyName(String companyId) async {
    final u = _users.firstWhere((u) => u.companies.contains(companyId), orElse: () => _users.first);
    return u.companyName.isNotEmpty ? u.companyName : 'Demo Company';
  }

  Future<User?> getUserData(String uid) async {
    return _users.firstWhere((u) => u.id == uid, orElse: () => null);
  }

  Future<User?> getUserByEmail(String email) async {
    return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase(), orElse: () => null);
  }

  Future<void> saveUserDataWithIndex(User user, {bool isNewUser = false}) async {
    final existingIndex = _users.indexWhere((u) => u.id == user.id);
    if (existingIndex >= 0) {
      _users[existingIndex] = user;
    } else {
      final id = user.id.isEmpty ? _uuid.v4() : user.id;
      _users.add(user.copyWith(id: id, createdAt: user.createdAt));
    }
    _emit();
  }

  Future<void> saveUserData(User user) async => saveUserDataWithIndex(user);

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    final idx = _users.indexWhere((u) => u.id == uid);
    if (idx < 0) return;
    final u = _users[idx];
    _users[idx] = u.copyWith(
      company: data['company'] ?? u.company,
      companyName: data['companyName'] ?? u.companyName,
    );
    _emit();
  }

  Future<void> updateUserField(String uid, String field, dynamic value) async {
    final idx = _users.indexWhere((u) => u.id == uid);
    if (idx < 0) return;
    final u = _users[idx];
    if (field == 'isActive') {
      _users[idx] = u.copyWith(isActive: value as bool);
    }
    _emit();
  }

  Stream<List<Map<String, dynamic>>> getPendingInvites(String userId) async* {
    // No invites in demo
    yield [];
  }

  Future<void> sendInvite({required String fromCompanyId, required String fromCompanyName, required String toUserId}) async {
    // no-op in demo
  }

  Future<void> respondToInvite(String inviteId, String status) async {
    // no-op in demo
  }

  Future<void> signOut() async {}

  // Auth simulation; returns a simple Map mimicking { user: { uid: '...' } }
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final u = await getUserByEmail(email);
    if (u == null) throw Exception('user-not-found');
    return {'user': {'uid': u.id}};
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final newUser = User(
      id: id,
      company: '',
      companyName: '',
      companies: [],
      roles: {},
      name: email.split('@').first,
      email: email,
      phone: '',
      document: '',
      birthDate: now,
      profile: 'AGENTE',
      isActive: true,
      zipCode: '',
      address: '',
      number: '',
      neighborhood: '',
      city: '',
      state: '',
      createdAt: now,
    );
    _users.add(newUser);
    _emit();
    return {'user': {'uid': id}};
  }

  void dispose() {
    _usersController.close();
  }
}
