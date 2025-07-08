import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];

  List<InventoryItem> get items => [..._items];

  // Get filtered items based on ShopProvider.currentShop
  List<InventoryItem> get filteredItems {
    // This will be accessed from the UI with ShopProvider context
    return _items;
  }

  // Get all available shop IDs from inventory items
  List<String> get availableShopIds {
    return _items.map((item) => item.shopId).toSet().toList();
  }

  // Get filtered items based on current shop (to be used with ShopProvider)
  List<InventoryItem> getItemsForShop(Shop? currentShop) {
    if (currentShop == null) {
      return _items; // Show all items when no shop is selected
    }
    return _items.where((item) => item.shopId == currentShop.id).toList();
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
            dataList.map(
              (item) => InventoryItem(
                id: item['id'],
                name: item['name'],
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'],
                lowStockThreshold: item['lowStockThreshold'],
                shopId: item['shopId'],
                createdBy: item['createdBy'],
              ),
            ),
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
            dataList
                .map(
                  (item) => InventoryItem(
                    id: item['id'],
                    name: item['name'],
                    price: (item['price'] as num).toDouble(),
                    quantity: item['quantity'],
                    lowStockThreshold: item['lowStockThreshold'],
                    shopId: item['shopId'],
                    createdBy: item['createdBy'],
                  ),
                )
                .toList();
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
    });
    _items.add(item);
    notifyListeners();
  }

  Future<void> saleStock(String productId, int quantitySold) async {
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
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;
      await ApiService.put('inventory/$id', {'quantity': newQuantity});
    }
  }

  Future<void> updateStock(String productId, int quantitySold) async {
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
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;

      await ApiService.put('inventory/$id', {'quantity': newQuantity});
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
    );
    _items[itemIndex] = updatedItem;
    notifyListeners();
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.update(
        'inventories',
        Map<String, Object>.from(updatedItem.toJson()),
        itemId,
      );
      return;
    }
    await ApiService.put('inventory/$itemId', {
      'price': newUnitPrice,
      'quantity': updatedItem.quantity,
    });
  }

  Future<void> decreaseStockForDamagedGoods(
    String productId,
    int damagedUnits,
  ) async {
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity - damagedUnits;
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        shopId: item.shopId,
        createdBy: item.createdBy,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;
      await ApiService.put('inventory/$id', {'quantity': newQuantity});
    }
  }

  Future<void> fetchAndSetInventoryHybrid(
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium) {
      final localItems = await DBHelper.getData('inventories');
      _items =
          localItems
              .map(
                (item) => InventoryItem(
                  id: item['id'],
                  name: item['name'],
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'],
                  lowStockThreshold: item['lowStockThreshold'],
                  shopId: item['shopId'],
                  createdBy: item['createdBy'],
                ),
              )
              .toList();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await fetchAndSetItems(businessProvider.id!);
    } else {
      final localItems = await DBHelper.getData('inventories');
      _items =
          localItems
              .map(
                (item) => InventoryItem(
                  id: item['id'],
                  name: item['name'],
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'],
                  lowStockThreshold: item['lowStockThreshold'],
                  shopId: item['shopId'],
                  createdBy: item['createdBy'],
                ),
              )
              .toList();
      notifyListeners();
    }
  }

  Future<void> addInventoryItemHybrid(
    InventoryItem item,
    String createdBy,
    String shopId,
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('inventories', {
        // ...all inventory fields...
        'synced': 0,
      });
      // ...add to _items...
      notifyListeners();
      return;
    }
    await addInventoryItem(item, createdBy, shopId);
  }

  Future<void> syncInventoryToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('inventories');
    for (final item in unsynced) {
      // ...send to backend via ApiService...
      await DBHelper.markAsSynced('inventories', item['id']);
    }
  }
}
