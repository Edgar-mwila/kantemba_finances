import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/user.dart';
import 'business_provider.dart';
import 'expenses_provider.dart';
import 'inventory_provider.dart';
import 'sales_provider.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

class UsersProvider with ChangeNotifier {
  List<User> _users = [];
  User? _currentUser;

  List<User> get users => [..._users];
  User? get currentUser => _currentUser;

  Future<void> fetchUsers(String businessId) async {
    final response = await ApiService.get('users?businessId=$businessId');
    if (response.statusCode != 200) {
      //Return some error
    }
    final dataList = json.decode(response.body);
    _users =
        (dataList as List)
            .map((item) => _userFromMap(item))
            .toList()
            .cast<User>();
    notifyListeners();
  }

  Future<bool> login(
    BuildContext context,
    String businessId,
    String contact,
    String password,
  ) async {
    final response = await ApiService.post('users/login', {
      'businessId': businessId,
      'contact': contact,
      'password': password,
    });
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = _userFromMap(data['user']);
      _currentUser = user;
      await ApiService.saveToken(data['token']);
      notifyListeners();
      // Set all providers using the businessId
      final businessProvider = Provider.of<BusinessProvider>(
        context,
        listen: false,
      );
      final expensesProvider = Provider.of<ExpensesProvider>(
        context,
        listen: false,
      );
      final inventoryProvider = Provider.of<InventoryProvider>(
        context,
        listen: false,
      );
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      await businessProvider.setBusiness(businessId);
      await expensesProvider.fetchAndSetExpenses(businessId);
      await inventoryProvider.fetchAndSetItems(businessId);
      await salesProvider.fetchAndSetSales(businessId);
      await fetchUsers(businessId);
      // Notify all providers that the user has logged in
      businessProvider.notifyListeners();
      expensesProvider.notifyListeners();
      inventoryProvider.notifyListeners();
      salesProvider.notifyListeners();

      return true;
    }
    return false;
  }

  Future<void> addUser(
    User user,
    String password,
    String contact,
    String businessId,
  ) async {
    final newUser = User(
      id: user.id,
      name: user.name,
      role: user.role,
      permissions: user.permissions,
    );
    _users.add(newUser);
    notifyListeners();
    await ApiService.post('users', {
      'id': newUser.id,
      'name': newUser.name,
      'password': password,
      'role': newUser.role.toString(),
      'permissions': json.encode(newUser.permissions),
      'contact': contact,
      'businessId': businessId,
    });
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> editUser(String id, User updatedUser) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _users[idx] = updatedUser;
      notifyListeners();

      // Update in database
      await ApiService.put('users/$id', {
        'id': updatedUser.id,
        'name': updatedUser.name,
        'role': updatedUser.role.toString(),
        'permissions': json.encode(updatedUser.permissions),
      });
    }
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    notifyListeners();

    // Delete from database
    await ApiService.delete('users/$id');
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiService.clearToken();
    notifyListeners();
  }

  User _userFromMap(Map<String, dynamic> item) {
    dynamic perms = item['permissions'];
    List<String> permissionsList;

    // Handle cases where permissions are stored as a double-encoded JSON string,
    // e.g. "\"[\\\"all\\\"]\""
    if (perms is String) {
      dynamic decoded = perms;
      // Keep decoding while the string looks like a JSON array
      while (decoded is String && decoded.trim().startsWith('[') ||
          (decoded is String && decoded.trim().startsWith('"['))) {
        try {
          decoded = json.decode(decoded);
        } catch (_) {
          break;
        }
      }
      if (decoded is List) {
        permissionsList = List<String>.from(decoded);
      } else if (decoded is String) {
        permissionsList = [decoded];
      } else {
        permissionsList = [];
      }
    } else if (perms is List) {
      permissionsList = List<String>.from(perms);
    } else {
      permissionsList = [];
    }

    return User(
      id: item['id'],
      name: item['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == item['role'],
        orElse: () => UserRole.owner,
      ),
      permissions: permissionsList,
    );
  }
}
