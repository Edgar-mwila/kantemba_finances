import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class UsersProvider with ChangeNotifier {
  List<User> _users = [];
  User? _currentUser;

  List<User> get users => [..._users];
  User? get currentUser => _currentUser;

  Future<void> fetchAndSetUsers() async {
    final dataList = await DBHelper.getData('users');
    if (dataList.isEmpty) {
      await _createDefaultUser();
      final defaultUserData = await DBHelper.getData('users');
      _users = defaultUserData.map((item) => _userFromMap(item)).toList();
      _currentUser = _users.first;
    } else {
      _users = dataList.map((item) => _userFromMap(item)).toList();
    }
    notifyListeners();
  }

  Future<void> _createDefaultUser() async {
    final hashedPassword = sha256.convert(utf8.encode('admin')).toString();
    final defaultUser = User(
      id: 'owner1',
      name: 'Owner1',
      role: UserRole.owner,
      permissions: ['all'],
    );
    await DBHelper.insert('users', {
      'id': defaultUser.id,
      'name': defaultUser.name,
      'password': hashedPassword,
      'role': defaultUser.role.toString(),
      'permissions': json.encode(defaultUser.permissions),
    });
  }

  Future<void> addUser(User user, String password) async {
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    final newUser = User(
      id: DateTime.now().toString(),
      name: user.name,
      role: user.role,
      permissions: user.permissions,
    );
    _users.add(newUser);
    notifyListeners();
    await DBHelper.insert('users', {
      'id': newUser.id,
      'name': newUser.name,
      'password': hashedPassword,
      'role': newUser.role.toString(),
      'permissions': json.encode(newUser.permissions),
    });
  }
  
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void editUser(String id, User updatedUser) {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _users[idx] = updatedUser;
      notifyListeners();
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  User _userFromMap(Map<String, dynamic> item) {
    return User(
      id: item['id'],
      name: item['name'],
      role: UserRole.values.firstWhere((e) => e.toString() == item['role']),
      permissions: List<String>.from(json.decode(item['permissions'])),
    );
  }
} 