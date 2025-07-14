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
      final token = await ApiService.getToken();

      if (userData != null && businessId != null) {
        final userMap = json.decode(userData);
        _currentUser = _userFromMap(userMap);

        // Check if we're online before validating token
        final isOnline = await ApiService.isOnline();

        if (isOnline && token != 'LocalLoginToken') {
          // Only validate token if online
          final isValidToken = await _validateStoredToken();

          if (!isValidToken) {
            // Token is invalid, clear the session
            await _clearStoredSession();
            _currentUser = null;
          } else {
            // Restore all providers with the saved business and user data
            initialize_providers(context, _currentUser!).catchError((e) {
              debugPrint('Provider initialization error: $e');
            });
          }
        } else {
          // Offline mode: just restore the user session without API calls
          // Set up basic providers for offline mode
          initialize_providers(context, _currentUser!).catchError((e) {
            debugPrint('Provider initialization error: $e');
          });
        }
      } else {
        // print('No stored session found'); // Removed print
      }
    } catch (e) {
      // print('Error during session restoration: $e'); // Removed print
      // If there's any error restoring the session, clear it
      await _clearStoredSession();
      _currentUser = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Method to check and restore user session if needed
  Future<bool> ensureUserSession(BuildContext context) async {
    if (_currentUser != null) {
      return true;
    }

    // Try to restore session
    if (!_isInitialized) {
      await initialize(context);
    }

    if (_currentUser == null) {
      // Try to restore from stored data
      try {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('current_user');
        final businessId = prefs.getString('business_id');

        if (userData != null && businessId != null) {
          final userMap = json.decode(userData);
          _currentUser = _userFromMap(userMap);
          notifyListeners();
          return _currentUser != null;
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }

    return _currentUser != null;
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
      // print('Token validation error: $e'); // Removed print
      // If there's a network error, we'll assume the token is still valid
      // but the server might be unreachable. In a production app, you might
      // want to be more strict about this.
      return true;
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
        'role': user.role,
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

  Future<void> initialize_providers(BuildContext context, User user) async {
    try {
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
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final returnsProvider = Provider.of<ReturnsProvider>(
        context,
        listen: false,
      );

      await businessProvider.setBusiness(user.businessId);

      // Check if online and if business is premium
      bool isOnline = await ApiService.isOnline();
      bool isPremium = businessProvider.isPremium;

      if (isOnline && isPremium) {
        // Online mode and premium business: fetch data from API
        await shopProvider.fetchShops(
          user.businessId,
          shopIds: user.shopId != null ? [user.shopId!] : [],
        );

        await Future.wait([
          expensesProvider.fetchAndSetExpenses(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
          inventoryProvider.fetchAndSetItems(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
          salesProvider.fetchAndSetSales(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
        ]).catchError((e) {
          debugPrint('Failed to fetch data in parallel: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error fetching data: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return [];
        });

        await returnsProvider
            .fetchReturns(
              user.businessId,
              shopIds: shopProvider.shops.map((s) => s.id).toList(),
            )
            .catchError((e) {
              debugPrint('Failed to fetch returns: $e');
            });

        await fetchUsers(user.businessId).catchError((e) {
          debugPrint('Failed to fetch users: $e');
        });
      } else {
        // Offline mode or non-premium business: load data from local database
        debugPrint(
          'Offline mode or non-premium business: loading data from local database',
        );

        // Load shops from local database
        await shopProvider.fetchShops(user.businessId);

        // Load other data from local database
        await Future.wait([
          expensesProvider.fetchAndSetExpenses(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
          inventoryProvider.fetchAndSetItems(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
          salesProvider.fetchAndSetSales(
            user.businessId,
            shopIds: shopProvider.shops.map((s) => s.id).toList(),
          ),
        ]).catchError((e) {
          debugPrint('Failed to load local data: $e');
          return [];
        });

        await returnsProvider
            .fetchReturns(
              user.businessId,
              shopIds: shopProvider.shops.map((s) => s.id).toList(),
            )
            .catchError((e) {
              debugPrint('Failed to load local returns: $e');
            });

        await fetchAndSetUsersHybrid(businessProvider).catchError((e) {
          debugPrint('Failed to load local users: $e');
        });
      }

      // Notify all providers that the user has logged in
      businessProvider.notifyListeners();
      expensesProvider.notifyListeners();
      inventoryProvider.notifyListeners();
      salesProvider.notifyListeners();
      returnsProvider.notifyListeners();
      shopProvider.notifyListeners();

      debugPrint('Provider initialization complete');
    } catch (e) {
      debugPrint('Provider initialization error: $e');
    }
  }

  Future<bool> login(
    BuildContext context,
    String contact,
    String password,
  ) async {
    try {
      // Show immediate feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking credentials...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      bool isOnline = await ApiService.isOnline();

      if (isOnline) {
        // Test backend connection first
        bool backendReachable = await ApiService.testConnection();

        if (!backendReachable) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot reach server. Trying offline login...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Fall through to offline login
        } else {
          try {
            final response = await ApiService.post('users/login', {
              'contact': contact,
              'password': password,
            });

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final user = _userFromMap(data['user']);
              _currentUser = user;
              await ApiService.saveToken(data['token']);
              await _saveUserSession(user, user.businessId);
              notifyListeners();

              // Initialize providers in background to avoid blocking UI
              initialize_providers(context, user).catchError((e) {
                debugPrint('Provider initialization error: $e');
              });

              return true;
            } else {
              // Handle specific error codes
              if (response.statusCode == 401) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid credentials. Please check your contact and password.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Server error (${response.statusCode}). Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              return false;
            }
          } catch (e) {
            // Network timeout or connection error
            debugPrint('Online login failed: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Network timeout. Trying offline login...'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    // Fallback to local DB login if offline or user not found online
    try {
      final users = await DBHelper.getData('users');

      if (users.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No users found in local database. Please create an account first.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      final userMap = users.firstWhere(
        (u) => u['contact'] == contact && u['password'] == password,
        orElse: () => <String, dynamic>{},
      );

      if (userMap.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid credentials. Please check your contact and password.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      final user = _userFromMap(userMap);
      _currentUser = user;
      await ApiService.saveToken('LocalLoginToken'); // No token for local login
      await _saveUserSession(user, user.businessId);
      notifyListeners();

      // Initialize providers in background
      initialize_providers(context, user).catchError((e) {
        debugPrint('Provider initialization error: $e');
      });

      return true;
    } catch (e) {
      debugPrint('Local database error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Local database error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    final businessProvider = BusinessProvider();
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('users', {
        'id': user.id,
        'name': user.name,
        'contact': contact,
        'role': user.role,
        'permissions': jsonEncode(user.permissions),
        'shopId': user.shopId ?? '',
        'businessId': user.businessId,
        'password': password,
        'synced': 0,
      });
      _users.add(user);
      notifyListeners();
      // Optionally, if this is a login or first user, persist session
      await _saveUserSession(user, businessId);
      return;
    }
    // Online: use API
    await ApiService.post('users', {
      'id': user.id,
      'name': user.name,
      'contact': user.contact,
      'role': user.role,
      'permissions': jsonEncode(user.permissions),
      'shopId': user.shopId,
      'businessId': user.businessId,
      'password': password,
    });
    _users.add(user);
    notifyListeners();
  }

  Future<void> setCurrentUser(User user, {String? businessId}) async {
    _currentUser = user;
    notifyListeners();
    if (businessId != null) {
      await _saveUserSession(user, businessId);
    }
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
        'role': updatedUser.role,
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

  User _userFromMap(Map<String, dynamic> map) {
    // Handle permissions which might be stored as JSON string or already as List
    List<String> permissions = [];
    if (map['permissions'] != null) {
      if (map['permissions'] is String) {
        // Parse JSON string to List
        try {
          final permissionsList = json.decode(map['permissions'] as String);
          if (permissionsList is List) {
            permissions = permissionsList.map((e) => e.toString()).toList();
          }
        } catch (e) {
          debugPrint('Error parsing permissions: $e');
          permissions = [];
        }
      } else if (map['permissions'] is List) {
        // Already a List, convert to List<String>
        permissions =
            (map['permissions'] as List).map((e) => e.toString()).toList();
      }
    }

    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      contact: map['contact'] as String,
      role: map['role'] as String,
      permissions: permissions,
      shopId: map['shopId'] as String?,
      businessId: map['businessId'] as String,
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
        'role': user.role,
        'permissions': json.encode(user.permissions),
        'shopId': user.shopId!,
        'businessId': businessId,
        'password': password,
        'synced': 0,
      });
      _users.add(user);
      notifyListeners();
      // Optionally, if this is a login or first user, persist session
      await _saveUserSession(user, businessId);
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
