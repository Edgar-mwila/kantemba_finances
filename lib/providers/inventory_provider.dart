import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/models/user.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];

  List<InventoryItem> get items => [..._items];

  List<String> get availableShopIds {
    return _items.map((item) => item.shopId).toSet().toList();
  }

  List<InventoryItem> getItemsForShop(Shop? currentShop) {
    if (currentShop == null) {
      return _items; // Show all items when no shop is selected
    }
    return _items.where((item) => item.shopId == currentShop.id).toList();
  }

  InventoryItem? findItemByBarcode(String barcode) {
    try {
      return _items.firstWhere(
        (item) =>
            item.barcode != null &&
            item.barcode!.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  bool barcodeExists(String barcode) {
    return _items.any(
      (item) =>
          item.barcode != null &&
          item.barcode!.toLowerCase() == barcode.toLowerCase(),
    );
  }

  List<InventoryItem> getItemsForShopAndDateRange(
    Shop? currentShop,
    DateTime? start,
    DateTime? end,
  ) {
    // InventoryItem does not have a date field, so just filter by shop for now
    return getItemsForShop(currentShop);
  }

  Future<void> fetchAndSetItems(
    String businessId, {
    List<String>? shopIds,
  }) async {
    bool isOnline = await ApiService.isOnline();
    final business = await DBHelper.getDataById('businesses', businessId);
    final isPremium = business?['isPremium'] == 1;

    if (!isOnline || !isPremium) {
      // Offline mode or non-premium business: load from local database
      debugPrint(
        'InventoryProvider: Loading items from local database (offline: ${!isOnline}, premium: $isPremium)',
      );
      final localItems = await DBHelper.getDataByShopId(
        'inventories',
        businessId,
      );
      _items =
          localItems.map((item) {
            final damagedRecords =
                (jsonDecode(item['damagedRecords'] ?? '[]') as List<dynamic>)
                    .map(
                      (e) => DamagedRecord.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();
            debugPrint(
              'Loaded ${damagedRecords.length} damaged records for ${item['name']}',
            );
            return InventoryItem(
              id: item['id'],
              name: item['name'],
              price: (item['price'] as num).toDouble(),
              quantity: item['quantity'],
              lowStockThreshold: item['lowStockThreshold'],
              shopId: item['shopId'],
              createdBy: item['createdBy'],
              barcode: item['barcode'], // Add barcode support
              damagedRecords: damagedRecords,
            );
          }).toList();
      notifyListeners();
      return;
    }

    // Online mode and premium business: fetch from API
    debugPrint('InventoryProvider: Loading items from API');
    List<InventoryItem> allItems = [];
    if (shopIds != null && shopIds.isNotEmpty) {
      for (final shopId in shopIds) {
        final query = 'inventory?businessId=$businessId&shopId=$shopId';
        final response = await ApiService.get(query);
        if (response.statusCode == 200) {
          dynamic data = json.decode(response.body);
          List<dynamic> dataList;
          if (data is List) {
            dataList = data;
          } else if (data is Map) {
            dataList = [data];
          } else if (data is String && data.trim().isNotEmpty) {
            var decoded = json.decode(data);
            if (decoded is List) {
              dataList = decoded;
            } else if (decoded is Map) {
              dataList = [decoded];
            } else {
              dataList = [];
            }
          } else {
            dataList = [];
          }
          allItems.addAll(
            dataList.map((item) {
              final damagedRecords =
                  (jsonDecode(item['damagedRecords'] ?? '[]') as List<dynamic>)
                      .map(
                        (e) =>
                            DamagedRecord.fromJson(e as Map<String, dynamic>),
                      )
                      .toList();
              debugPrint(
                'API: Loaded ${damagedRecords.length} damaged records for ${item['name']}',
              );
              return InventoryItem(
                id: item['id'],
                name: item['name'],
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'],
                lowStockThreshold: item['lowStockThreshold'],
                shopId: item['shopId'],
                createdBy: item['createdBy'],
                barcode: item['barcode'], // Add barcode support
                damagedRecords: damagedRecords,
              );
            }),
          );
        }
      }
    } else {
      // No shopIds: fetch all for businessId
      final query = 'inventory?businessId=$businessId';
      final response = await ApiService.get(query);
      if (response.statusCode == 200) {
        dynamic data = json.decode(response.body);
        List<dynamic> dataList;
        if (data is List) {
          dataList = data;
        } else if (data is Map) {
          dataList = [data];
        } else if (data is String && data.trim().isNotEmpty) {
          var decoded = json.decode(data);
          if (decoded is List) {
            dataList = decoded;
          } else if (decoded is Map) {
            dataList = [decoded];
          } else {
            dataList = [];
          }
        } else {
          dataList = [];
        }
        allItems =
            dataList.map((item) {
              final damagedRecords =
                  (jsonDecode(item['damagedRecords'] ?? '[]') as List<dynamic>)
                      .map(
                        (e) =>
                            DamagedRecord.fromJson(e as Map<String, dynamic>),
                      )
                      .toList();
              debugPrint(
                'API: Loaded ${damagedRecords.length} damaged records for ${item['name']}',
              );
              return InventoryItem(
                id: item['id'],
                name: item['name'],
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'],
                lowStockThreshold: item['lowStockThreshold'],
                shopId: item['shopId'],
                createdBy: item['createdBy'],
                barcode: item['barcode'], // Add barcode support
                damagedRecords: damagedRecords,
              );
            }).toList();
      }
    }
    _items = allItems;
    notifyListeners();
  }

  Future<void> addInventoryItem(
    InventoryItem item,
    String createdBy,
    String shopId,
  ) async {
    final businessProvider = BusinessProvider();
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('inventories', {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'lowStockThreshold': item.lowStockThreshold,
        'createdBy': createdBy,
        'shopId': shopId,
        'barcode': item.barcode ?? '', // Handle nullable barcode
        'damagedRecords': jsonEncode(
          item.damagedRecords.map((e) => e.toJson()).toList(),
        ),
        'synced': 0,
      });
      _items.add(item);
      notifyListeners();
      return;
    }
    // Online: use API
    await ApiService.post('inventory', {
      'id': item.id,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'lowStockThreshold': item.lowStockThreshold,
      'createdBy': createdBy,
      'shopId': shopId,
      'barcode': item.barcode, // Add barcode support
    });
    _items.add(item);
    notifyListeners();
  }

  Future<void> saleStock(String productId, int quantitySold) async {
    final businessProvider = BusinessProvider();
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity - quantitySold;
      if (newQuantity < 0) {
        throw Exception('Not enough stock to complete the sale.');
      }
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: (item.price as num).toDouble(),
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
        damagedRecords: item.damagedRecords,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      // Handle both local DB and API
      if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
        await DBHelper.update('inventories', {
          'quantity': newQuantity,
          'damagedRecords': jsonEncode(
            updatedItem.damagedRecords.map((e) => e.toJson()).toList(),
          ),
        }, productId);
      } else {
        await ApiService.put('inventory/$productId', {'quantity': newQuantity});
      }
    }
  }

  Future<void> updateStock(String productId, int quantitySold) async {
    final businessProvider = BusinessProvider();
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity - quantitySold;
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: (item.price as num).toDouble(),
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
        damagedRecords: item.damagedRecords,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      // Handle both local DB and API
      if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
        await DBHelper.update('inventories', {
          'quantity': newQuantity,
          'damagedRecords': jsonEncode(
            updatedItem.damagedRecords.map((e) => e.toJson()).toList(),
          ),
        }, productId);
      } else {
        await ApiService.put('inventory/$productId', {'quantity': newQuantity});
      }
    }
  }

  Future<void> increaseStockAndUpdatePrice(
    String itemId,
    int additionalUnits,
    double newUnitPrice,
  ) async {
    final businessProvider = BusinessProvider();
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;
    final item = _items[itemIndex];
    final updatedItem = InventoryItem(
      id: item.id,
      name: item.name,
      price: newUnitPrice,
      quantity: item.quantity + additionalUnits,
      lowStockThreshold: item.lowStockThreshold,
      shopId: item.shopId,
      createdBy: item.createdBy,
      damagedRecords: item.damagedRecords,
    );
    _items[itemIndex] = updatedItem;
    notifyListeners();
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.update('inventories', {
        'price': newUnitPrice,
        'quantity': updatedItem.quantity,
        'damagedRecords': jsonEncode(
          updatedItem.damagedRecords.map((e) => e.toJson()).toList(),
        ),
      }, itemId);
      return;
    }
    await ApiService.put('inventory/$itemId', {
      'price': newUnitPrice,
      'quantity': updatedItem.quantity,
    });
  }

  Future<void> increaseStockAndUpdatePriceWithBulkPurchase(
    String itemId,
    int additionalUnits,
    double newUnitPrice,
    double bulkPrice,
    bool addAsExpense,
  ) async {
    try {
      final businessProvider = BusinessProvider();
      final expensesProvider = ExpensesProvider();
      final userProvider = UsersProvider();
      final shopProvider = ShopProvider();

      // Note: We can't access context here, so we'll handle session restoration differently
      if (userProvider.currentUser == null) {
        debugPrint('No current user found, attempting to restore session...');

        // Try to restore from stored data directly
        try {
          final prefs = await SharedPreferences.getInstance();
          final userData = prefs.getString('current_user');
          final businessId = prefs.getString('business_id');

          if (userData != null && businessId != null) {
            final userMap = json.decode(userData);
            userProvider.setCurrentUser(
              _userFromMap(userMap),
              businessId: businessId,
            );
          } else {
            throw Exception('User session not available. Please log in again.');
          }
        } catch (e) {
          debugPrint('Error restoring user session: $e');
          throw Exception('User session not available. Please log in again.');
        }
      }

      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        debugPrint('Item not found: $itemId');
        throw Exception('Item not found');
      }

      final item = _items[itemIndex];
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: newUnitPrice,
        quantity: item.quantity + additionalUnits,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
        damagedRecords: item.damagedRecords,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
        // Update inventory
        await DBHelper.update('inventories', {
          'price': newUnitPrice,
          'quantity': updatedItem.quantity,
        }, itemId);

        // Add expense if requested
        if (addAsExpense) {
          // Check if currentUser is available
          if (userProvider.currentUser == null) {
            debugPrint(
              'Warning: No current user available for expense creation',
            );
            throw Exception('No current user available. Please log in again.');
          }
        }
        return;
      }

      // Online mode
      await ApiService.put('inventory/$itemId', {
        'price': newUnitPrice,
        'quantity': updatedItem.quantity,
      });

      if (addAsExpense) {
        // Check if currentUser is available
        if (userProvider.currentUser == null) {
          debugPrint('Warning: No current user available for expense creation');
          throw Exception('No current user available. Please log in again.');
        }

        final expenseId = 'expense_${DateTime.now().millisecondsSinceEpoch}';
        final currentShopId = shopProvider.currentShop?.id ?? item.shopId;

        final expense = Expense(
          id: expenseId,
          description:
              'Bulk purchase: ${item.name} (${additionalUnits} units @ K${bulkPrice.toStringAsFixed(2)})',
          amount: bulkPrice,
          date: DateTime.now(),
          category: 'Inventory Purchase',
          createdBy: userProvider.currentUser!.id,
          shopId: currentShopId,
        );

        await expensesProvider.addExpenseHybrid(
          expense,
          userProvider.currentUser!.id,
          currentShopId,
          businessProvider,
        );

        // Refresh expenses list after adding expense
        await expensesProvider.fetchAndSetExpensesHybrid(businessProvider);
      }
    } catch (e) {
      debugPrint('Error in increaseStockAndUpdatePriceWithBulkPurchase: $e');
      rethrow;
    }
  }

  User _userFromMap(Map<String, dynamic> map) {
    List<String> permissions = [];
    if (map['permissions'] != null) {
      if (map['permissions'] is String) {
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

  Future<void> decreaseStockForDamagedGoods(
    String productId,
    int damagedUnits,
    String reason,
  ) async {
    final businessProvider = BusinessProvider();
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity - damagedUnits;
      final newRecord = DamagedRecord(
        units: damagedUnits,
        reason: reason,
        date: DateTime.now(),
      );
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
        damagedRecords: [...item.damagedRecords, newRecord],
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      // Calculate the value of damaged goods
      final damagedValue = damagedUnits * item.price;

      if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
        // Update inventory
        await DBHelper.update('inventories', {
          'quantity': newQuantity,
          'damagedRecords': jsonEncode(
            updatedItem.damagedRecords.map((e) => e.toJson()).toList(),
          ),
        }, productId);

        debugPrint(
          'Saved damaged records to local DB: ${updatedItem.damagedRecords.length} records',
        );

        // Add expense for damaged goods
        final expenseId = 'expense_${DateTime.now().millisecondsSinceEpoch}';
        await DBHelper.insert('expenses', {
          'id': expenseId,
          'description':
              'Damaged goods: ${item.name} (${damagedUnits} units @ K${item.price.toStringAsFixed(2)} each) - ${reason}',
          'amount': damagedValue,
          'date': DateTime.now().toIso8601String(),
          'category': 'Damaged Goods',
          'createdBy': item.createdBy,
          'shopId': item.shopId,
          'synced': 0,
        });
      } else {
        // Online mode
        await ApiService.put('inventory/$productId', updatedItem.toJson());

        debugPrint(
          'Saved damaged records to backend: ${updatedItem.damagedRecords.length} records',
        );

        // Add expense for damaged goods
        await ApiService.post('expenses', {
          'description':
              'Damaged goods: ${item.name} (${damagedUnits} units @ K${item.price.toStringAsFixed(2)} each) - ${reason}',
          'amount': damagedValue,
          'date': DateTime.now().toIso8601String(),
          'category': 'Damaged Goods',
          'createdBy': item.createdBy,
          'shopId': item.shopId,
        });
      }
    }
  }

  Future<void> reimburseStockForReturn(
    String productId,
    int returnedQuantity,
  ) async {
    final businessProvider = BusinessProvider();
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity + returnedQuantity;

      debugPrint(
        'Reimbursing stock: ${item.name} - adding ${returnedQuantity} units (${item.quantity} -> ${newQuantity})',
      );

      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
        damagedRecords: item.damagedRecords,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      // Update database
      if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
        await DBHelper.update('inventories', {
          'quantity': newQuantity,
          'damagedRecords': jsonEncode(
            updatedItem.damagedRecords.map((e) => e.toJson()).toList(),
          ),
        }, productId);
        debugPrint(
          'Updated inventory in local DB: ${item.name} - ${newQuantity} units',
        );
      } else {
        await ApiService.put('inventory/$productId', {'quantity': newQuantity});
        debugPrint(
          'Updated inventory via API: ${item.name} - ${newQuantity} units',
        );
      }
    } else {
      debugPrint('Warning: Could not find inventory item with ID: $productId');
    }
  }

  Future<void> fetchAndSetInventoryHybrid(
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium) {
      final localItems = await DBHelper.getDataByShopId(
        'inventories',
        businessProvider.id!,
      );
      _items =
          localItems.map((item) {
            final damagedRecords =
                (jsonDecode(item['damagedRecords'] ?? '[]') as List<dynamic>)
                    .map(
                      (e) => DamagedRecord.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();
            debugPrint(
              'Hybrid: Loaded ${damagedRecords.length} damaged records for ${item['name']}',
            );
            return InventoryItem(
              id: item['id'],
              name: item['name'],
              price: (item['price'] as num).toDouble(),
              quantity: item['quantity'],
              lowStockThreshold: item['lowStockThreshold'],
              shopId: item['shopId'],
              createdBy: item['createdBy'],
              damagedRecords: damagedRecords,
            );
          }).toList();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await fetchAndSetItems(businessProvider.id!);
    } else {
      final localItems = await DBHelper.getDataByShopId(
        'inventories',
        businessProvider.id!,
      );
      _items =
          localItems.map((item) {
            final damagedRecords =
                (jsonDecode(item['damagedRecords'] ?? '[]') as List<dynamic>)
                    .map(
                      (e) => DamagedRecord.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();
            debugPrint(
              'Hybrid: Loaded ${damagedRecords.length} damaged records for ${item['name']}',
            );
            return InventoryItem(
              id: item['id'],
              name: item['name'],
              price: (item['price'] as num).toDouble(),
              quantity: item['quantity'],
              lowStockThreshold: item['lowStockThreshold'],
              shopId: item['shopId'],
              createdBy: item['createdBy'],
              damagedRecords: damagedRecords,
            );
          }).toList();
      notifyListeners();
    }
  }
}
