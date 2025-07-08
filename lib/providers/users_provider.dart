import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/user.dart';
import 'business_provider.dart';
import 'expenses_provider.dart';
import 'inventory_provider.dart';
import 'sales_provider.dart';
import 'returns_provider.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'shop_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class UsersProvider with ChangeNotifier {
  List<User> _users = [];
  User? _currentUser;
  bool _isInitialized = false;

  List<User> get users => [..._users];
  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  // Initialize the provider and restore user session if available
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('current_user');
      final businessId = prefs.getString('business_id');

      if (userData != null && businessId != null) {
        final userMap = json.decode(userData);
        _currentUser = _userFromMap(userMap);

        // Validate the stored token
        final isValidToken = await _validateStoredToken();

        if (!isValidToken) {
          // Token is invalid, clear the session
          await _clearStoredSession();
          _currentUser = null;
        } else {
          // Restore all providers with the saved business and user data
          await _restoreProviders(context, businessId);
        }
      } else {
        print('No stored session found');
      }
    } catch (e) {
      // If there's any error restoring the session, clear it
      await _clearStoredSession();
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Validate the stored token by making a test API call
  Future<bool> _validateStoredToken() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;

      // Make a simple API call to validate the token
      final response = await ApiService.get('users/validate');
      return response.statusCode == 200;
    } catch (e) {
      // If there's a network error, we'll assume the token is still valid
      // but the server might be unreachable. In a production app, you might
      // want to be more strict about this.
      return true;
    }
  }

  // Restore all providers with the saved business and user data
  Future<void> _restoreProviders(
    BuildContext context,
    String businessId,
  ) async {
    try {
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
      final returnsProvider = Provider.of<ReturnsProvider>(
        context,
        listen: false,
      );
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      await businessProvider.setBusiness(businessId);

      List<String> shopIds = [];
      List<Shop> shops = [];

      if (_currentUser!.shopId != null) {
        // Employee: single shop
        shopIds = [_currentUser!.shopId!];
        final shopResponse = await ApiService.get(
          'shops/${_currentUser!.shopId}',
        );
        if (shopResponse.statusCode == 200) {
          final shopData = json.decode(shopResponse.body);
          shops = [Shop.fromJson(shopData)];
        }
      } else if (_currentUser!.role == UserRole.manager) {
        // Manager: fetch assigned shopIds from backend
        final managerShopsResponse = await ApiService.get(
          'shops?userId=${_currentUser!.id}',
        );
        if (managerShopsResponse.statusCode == 200) {
          final List<dynamic> managerShops = json.decode(
            managerShopsResponse.body,
          );
          shopIds = managerShops.map((e) => e['shopId'] as String).toList();
          // Fetch all assigned shops
          for (final shopId in shopIds) {
            final shopResponse = await ApiService.get('shops/$shopId');
            if (shopResponse.statusCode == 200) {
              final shopData = json.decode(shopResponse.body);
              shops.add(Shop.fromJson(shopData));
            }
          }
        }
      } else if (_currentUser!.role == UserRole.admin) {
        // Admin: fetch all shopIds for the business
        final shopsResponse = await ApiService.get(
          'shops?businessId=$businessId',
        );
        if (shopsResponse.statusCode == 200) {
          final List<dynamic> shopsData = json.decode(shopsResponse.body);
          shopIds = shopsData.map((e) => e['id'] as String).toList();
          shops = shopsData.map((e) => Shop.fromJson(e)).toList();
        }
      }

      // Update ShopProvider with the relevant shops
      shopProvider.setShops(shops);
      if (shops.isNotEmpty) {
        shopProvider.setCurrentShop(shops.first);
      }

      // Fetch and combine data for all relevant shopIds
      await Future.wait([
        expensesProvider.fetchAndSetExpenses(businessId, shopIds: shopIds),
        inventoryProvider.fetchAndSetItems(businessId, shopIds: shopIds),
        salesProvider.fetchAndSetSales(businessId, shopIds: shopIds),
        returnsProvider.fetchReturns(businessId, shopIds: shopIds),
        fetchUsers(businessId),
      ]);

      // Notify all providers that the user session has been restored
      businessProvider.notifyListeners();
      expensesProvider.notifyListeners();
      inventoryProvider.notifyListeners();
      salesProvider.notifyListeners();
      shopProvider.notifyListeners();
      returnsProvider.notifyListeners();
    } catch (e) {
      // If there's any error restoring providers, clear the session
      await _clearStoredSession();
      _currentUser = null;
    }
  }

  // Save user session to SharedPreferences
  Future<void> _saveUserSession(User user, String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'current_user',
      json.encode({
        'id': user.id,
        'name': user.name,
        'contact': user.contact,
        'role': user.role.toString(),
        'permissions': user.permissions,
        'shopId': user.shopId,
        'businessId': user.businessId,
      }),
    );
    await prefs.setString('business_id', businessId);
  }

  // Clear stored user session
  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('business_id');
  }

  // Public method to clear stored session (for testing/debugging)
  Future<void> clearStoredSession() async {
    await _clearStoredSession();
    _currentUser = null;
    notifyListeners();
  }

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
    try {
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

        // Save user session to SharedPreferences
        await _saveUserSession(user, businessId);

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
        final salesProvider = Provider.of<SalesProvider>(
          context,
          listen: false,
        );
        final shopProvider = Provider.of<ShopProvider>(context, listen: false);

        await businessProvider.setBusiness(businessId);

        List<String> shopIds = [];
        List<Shop> shops = [];
        if (user.shopId != null) {
          // Employee: single shop
          shopIds = [user.shopId!];
          // Fetch only the assigned shop
          final shopResponse = await ApiService.get('shops/${user.shopId}');
          if (shopResponse.statusCode == 200) {
            final shopData = json.decode(shopResponse.body);
            shops = [Shop.fromJson(shopData)];
          }
        } else if (user.role == UserRole.manager) {
          // Manager: fetch assigned shopIds from backend
          final managerShopsResponse = await ApiService.get(
            'shops?userId=${user.id}',
          );
          if (managerShopsResponse.statusCode == 200) {
            final List<dynamic> managerShops = json.decode(
              managerShopsResponse.body,
            );
            shopIds = managerShops.map((e) => e['shopId'] as String).toList();
            // Fetch all assigned shops
            for (final shopId in shopIds) {
              final shopResponse = await ApiService.get('shops/$shopId');
              if (shopResponse.statusCode == 200) {
                final shopData = json.decode(shopResponse.body);
                shops.add(Shop.fromJson(shopData));
              }
            }
          }
        } else if (user.role == UserRole.admin) {
          // Admin: fetch all shopIds for the business
          final shopsResponse = await ApiService.get(
            'shops?businessId=$businessId',
          );
          if (shopsResponse.statusCode == 200) {
            final List<dynamic> shopsData = json.decode(shopsResponse.body);
            shopIds = shopsData.map((e) => e['id'] as String).toList();
            shops = shopsData.map((e) => Shop.fromJson(e)).toList();
          }
        }

        // Update ShopProvider with the relevant shops
        shopProvider.setShops(shops);
        if (shops.isNotEmpty) {
          shopProvider.setCurrentShop(shops.first);
        }

        // Fetch and combine data for all relevant shopIds
        await expensesProvider.fetchAndSetExpenses(
          businessId,
          shopIds: shopIds,
        );
        await inventoryProvider.fetchAndSetItems(businessId, shopIds: shopIds);
        await salesProvider.fetchAndSetSales(businessId, shopIds: shopIds);

        // Fetch returns data
        final returnsProvider = Provider.of<ReturnsProvider>(
          context,
          listen: false,
        );
        await returnsProvider.fetchReturns(businessId, shopIds: shopIds);

        await fetchUsers(businessId);
        // Notify all providers that the user has logged in
        businessProvider.notifyListeners();
        expensesProvider.notifyListeners();
        inventoryProvider.notifyListeners();
        salesProvider.notifyListeners();
        returnsProvider.notifyListeners();
        shopProvider.notifyListeners();

        return true;
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login failed: Please check your credentials and try again.',
            ),
          ),
        );
      }
      return false;
    }
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
      contact: contact,
      role: user.role,
      permissions: user.permissions,
      shopId: user.shopId,
      businessId: businessId,
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
      'shopId': newUser.shopId,
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
        'contact': updatedUser.contact,
        'shopId': updatedUser.shopId,
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
    await _clearStoredSession();
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

    // Handle empty role string - default to admin for business owners
    String roleString = item['role'] ?? '';
    if (roleString.isEmpty) {
      // If role is empty but user has "all" permissions, they're likely an admin/owner
      if (permissionsList.contains('all') ||
          permissionsList.contains(UserPermissions.all)) {
        roleString = 'admin';
      } else {
        roleString = 'employee'; // Default fallback
      }
    }

    return User(
      id: item['id'],
      name: item['name'],
      contact: item['contact'],
      role: UserRole.values.firstWhere(
        (e) => e.value == roleString,
        orElse: () => UserRole.admin,
      ),
      permissions: permissionsList,
      shopId: item['shopId'], // This can be null, which is fine
      businessId: item['businessId'],
    );
  }

  Future<void> fetchAndSetUsersHybrid(BusinessProvider businessProvider) async {
    if (!businessProvider.isPremium) {
      final localUsers = await DBHelper.getData('users');
      _users =
          localUsers.map((item) => _userFromMap(item)).toList().cast<User>();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await fetchUsers(businessProvider.id!);
      // Optionally, update local DB with latest online data
    } else {
      final localUsers = await DBHelper.getData('users');
      _users =
          localUsers.map((item) => _userFromMap(item)).toList().cast<User>();
      notifyListeners();
    }
  }

  Future<void> addUserHybrid(
    User user,
    String password,
    String businessId,
    String contact,
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('users', {
        'id': user.id,
        'name': user.name,
        'contact': contact,
        'role': user.role.toString(),
        'permissions': json.encode(user.permissions),
        'shopId': user.shopId!,
        'businessId': businessId,
        'synced': 0,
      });
      _users.add(user);
      notifyListeners();
      return;
    }
    await addUser(user, password, contact, businessId);
  }

  Future<void> syncUsersToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('users');
    for (final user in unsynced) {
      await ApiService.post('users', user);
      await DBHelper.markAsSynced('users', user['id']);
    }
  }
}
