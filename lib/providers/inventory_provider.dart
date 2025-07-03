import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/inventory_item.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];

  List<InventoryItem> get items => [..._items];

  Future<void> fetchAndSetItems(String businessId) async {
    final response = await ApiService.get('inventory?businessId=$businessId');
    if (response.statusCode != 200) {
      //Return some error.
    }
    if (kDebugMode) {
      print('Inventory API response: ${response.body}');
    }
    dynamic data = json.decode(response.body);
    List<dynamic> dataList;

    if (data is List) {
      dataList = data;
    } else if (data is Map) {
      dataList = [data];
    } else if (data is String && data.trim().isNotEmpty) {
      // Try to decode again if it's a JSON string
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
    try {
      _items =
          dataList.map((item) {
            try {
              return InventoryItem(
                id: item['id'],
                name: item['name'],
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'],
                lowStockThreshold: item['lowStockThreshold'],
                createdBy: item['createdBy'],
              );
            } catch (e, stack) {
              if (kDebugMode) {
                print('Error mapping item: $item');
                print('Error: $e');
                print('Stack: $stack');
              }
              rethrow;
            }
          }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in mapping dataList: $e');
      }
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addInventoryItem(
    InventoryItem item,
    String businessId,
    String createdBy,
  ) async {
    final newItem = InventoryItem(
      id: '${businessId}_${DateTime.now().toString()}',
      name: item.name,
      price: (item.price as num).toDouble(),
      quantity: item.quantity,
      lowStockThreshold: item.lowStockThreshold,
      createdBy: createdBy,
    );
    _items.add(newItem);
    notifyListeners();

    await ApiService.post('inventory', {
      'id': newItem.id,
      'name': newItem.name,
      'price': newItem.price,
      'quantity': newItem.quantity,
      'lowStockThreshold': newItem.lowStockThreshold,
      'businessId': businessId,
      'createdBy': newItem.createdBy,
    });
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
        createdBy: item.createdBy,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;

      await ApiService.put('inventory/$id', {'quantity': newQuantity});
    }
  }

  Future<void> increaseStockAndUpdatePrice(
    String productId,
    int additionalUnits,
    double newUnitPrice,
  ) async {
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: (newUnitPrice as num).toDouble(),
        quantity: item.quantity + additionalUnits,
        lowStockThreshold: item.lowStockThreshold,
        createdBy: item.createdBy,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;
      await ApiService.put('inventory/$id', {
        'quantity': updatedItem.quantity,
        'price': updatedItem.price,
      });
    }
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
        createdBy: item.createdBy,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();
      final id = item.id;
      await ApiService.put('inventory/$id', {'quantity': newQuantity});
    }
  }
}
