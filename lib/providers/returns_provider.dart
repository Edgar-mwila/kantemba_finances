import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/return.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class ReturnsProvider with ChangeNotifier {
  List<Return> _returns = [];

  List<Return> get returns => [..._returns];

  // Get filtered returns based on current shop
  List<Return> getReturnsForShop(Shop? currentShop) {
    if (currentShop == null) {
      return _returns; // Show all returns when no shop is selected
    }
    return _returns.where((ret) => ret.shopId == currentShop.id).toList();
  }

  // Get returns for a specific sale
  List<Return> getReturnsForSale(String saleId) {
    return _returns.where((ret) => ret.originalSaleId == saleId).toList();
  }

  // Calculate total return amount for a sale
  double getTotalReturnAmountForSale(String saleId) {
    final saleReturns = getReturnsForSale(saleId);
    return saleReturns.fold(0.0, (sum, ret) => sum + ret.grandReturnAmount);
  }

  // Check if a sale has any returns
  bool hasReturns(String saleId) {
    return _returns.any((ret) => ret.originalSaleId == saleId);
  }

  Future<void> fetchReturns(String businessId, {List<String>? shopIds}) async {
    List<Return> allReturns = [];

    try {
      if (shopIds != null && shopIds.isNotEmpty) {
        for (final shopId in shopIds) {
          final query = 'returns?businessId=$businessId&shopId=$shopId';
          final response = await ApiService.get(query);
          if (response.statusCode == 200) {
            final data = _parseJsonResponse(response.body, 'returns');
            if (data != null) {
              final returnsList = _processReturnsData(data);
              allReturns.addAll(returnsList);
            }
          }
        }
      } else {
        // Fetch all returns for business
        final query = 'returns?businessId=$businessId';
        final response = await ApiService.get(query);
        if (response.statusCode == 200) {
          final data = _parseJsonResponse(response.body, 'returns');
          if (data != null) {
            final returnsList = _processReturnsData(data);
            allReturns.addAll(returnsList);
          }
        }
      }

      _returns = allReturns;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching returns: $e');
    }
  }

  Future<void> createReturn(
    Sale originalSale,
    List<ReturnItem> returnItems,
    String reason,
    String createdBy,
    String shopId,
  ) async {
    try {
      // Calculate return amounts
      final totalReturnAmount = returnItems.fold(
        0.0,
        (sum, item) => sum + item.totalAmount,
      );

      // Calculate taxes proportionally
      final originalTotal = originalSale.totalAmount;
      final returnRatio = totalReturnAmount / originalTotal;

      final vat = originalSale.vat * returnRatio;
      final turnoverTax = originalSale.turnoverTax * returnRatio;
      final levy = originalSale.levy * returnRatio;

      final grandReturnAmount = totalReturnAmount + vat + turnoverTax + levy;

      final returnId = 'RET_${DateTime.now().millisecondsSinceEpoch}';

      final newReturn = Return(
        id: returnId,
        originalSaleId: originalSale.id,
        items: returnItems,
        totalReturnAmount: totalReturnAmount,
        grandReturnAmount: grandReturnAmount,
        vat: vat,
        turnoverTax: turnoverTax,
        levy: levy,
        date: DateTime.now(),
        shopId: shopId,
        createdBy: createdBy,
        reason: reason,
        status: 'approved', // Always approved
      );

      // Add to local list
      _returns.add(newReturn);
      notifyListeners();

      // Send to API
      final response = await ApiService.post('returns', newReturn.toJson());
      if (response.statusCode != 201) {
        debugPrint('Failed to create return: ${response.statusCode}');
        // Remove from local list if API call failed
        _returns.remove(newReturn);
        notifyListeners();
        throw Exception('Failed to create return');
      }

      // Update inventory (restock items)
      await _updateInventoryForReturn(returnItems, shopId);
    } catch (e) {
      debugPrint('Error creating return: $e');
      rethrow;
    }
  }

  Future<void> _updateInventoryForReturn(
    List<ReturnItem> returnItems,
    String shopId,
  ) async {
    try {
      for (final returnItem in returnItems) {
        // Increase inventory quantity
        await ApiService.put('inventory/${returnItem.product.id}', {
          'quantity': returnItem.product.quantity + returnItem.quantity,
        });
      }
    } catch (e) {
      debugPrint('Error updating inventory for return: $e');
      rethrow;
    }
  }

  // Helper methods for JSON parsing
  dynamic _parseJsonResponse(String body, String key) {
    if (body.isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey(key)) {
        return decoded[key];
      } else if (decoded is List) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing JSON response: $e');
      return null;
    }
  }

  List<Return> _processReturnsData(dynamic data) {
    final List<Return> returns = [];

    if (data is List) {
      for (final item in data) {
        try {
          if (item is Map<String, dynamic>) {
            returns.add(Return.fromJson(item));
          }
        } catch (e) {
          debugPrint('Error processing return item: $e');
        }
      }
    }

    return returns;
  }

  Future<void> fetchAndSetReturnsHybrid(
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium) {
      final localReturns = await DBHelper.getData('returns');
      final localReturnItems = await DBHelper.getData('return_items');
      // Map returnId to items
      final Map<String, List<ReturnItem>> itemsByReturnId = {};
      for (final item in localReturnItems) {
        final returnId = item['returnId'] as String;
        itemsByReturnId.putIfAbsent(returnId, () => []);
        itemsByReturnId[returnId]!.add(
          ReturnItem(
            product: InventoryItem(
              id: item['productId'],
              name: item['productName'],
              price: (item['originalPrice'] as num).toDouble(),
              quantity: 0,
              shopId: item['shopId'],
              createdBy: '',
            ),
            quantity: item['quantity'] as int,
            originalPrice: (item['originalPrice'] as num).toDouble(),
            reason: item['reason'] ?? '',
          ),
        );
      }
      _returns =
          localReturns.map((json) {
            final ret = Return.fromJson(json);
            return Return(
              id: ret.id,
              originalSaleId: ret.originalSaleId,
              items: itemsByReturnId[ret.id] ?? [],
              totalReturnAmount: ret.totalReturnAmount,
              grandReturnAmount: ret.grandReturnAmount,
              vat: ret.vat,
              turnoverTax: ret.turnoverTax,
              levy: ret.levy,
              date: ret.date,
              shopId: ret.shopId,
              createdBy: ret.createdBy,
              reason: ret.reason,
              status: ret.status,
            );
          }).toList();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await fetchReturns(businessProvider.id!);
      // Optionally, update local DB with latest online data
    } else {
      final localReturns = await DBHelper.getData('returns');
      final localReturnItems = await DBHelper.getData('return_items');
      final Map<String, List<ReturnItem>> itemsByReturnId = {};
      for (final item in localReturnItems) {
        final returnId = item['returnId'] as String;
        itemsByReturnId.putIfAbsent(returnId, () => []);
        itemsByReturnId[returnId]!.add(
          ReturnItem(
            product: InventoryItem(
              id: item['productId'],
              name: item['productName'],
              price: (item['originalPrice'] as num).toDouble(),
              quantity: 0,
              shopId: item['shopId'],
              createdBy: '',
            ),
            quantity: item['quantity'] as int,
            originalPrice: (item['originalPrice'] as num).toDouble(),
            reason: item['reason'] ?? '',
          ),
        );
      }
      _returns =
          localReturns.map((json) {
            final ret = Return.fromJson(json);
            return Return(
              id: ret.id,
              originalSaleId: ret.originalSaleId,
              items: itemsByReturnId[ret.id] ?? [],
              totalReturnAmount: ret.totalReturnAmount,
              grandReturnAmount: ret.grandReturnAmount,
              vat: ret.vat,
              turnoverTax: ret.turnoverTax,
              levy: ret.levy,
              date: ret.date,
              shopId: ret.shopId,
              createdBy: ret.createdBy,
              reason: ret.reason,
              status: ret.status,
            );
          }).toList();
      notifyListeners();
    }
  }

  Future<void> addReturnHybrid(
    Return ret,
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('returns', {
        'id': ret.id,
        'originalSaleId': ret.originalSaleId,
        'totalReturnAmount': ret.totalReturnAmount,
        'grandReturnAmount': ret.grandReturnAmount,
        'vat': ret.vat,
        'turnoverTax': ret.turnoverTax,
        'levy': ret.levy,
        'date': ret.date.toIso8601String(),
        'shopId': ret.shopId,
        'createdBy': ret.createdBy,
        'reason': ret.reason,
        'status': ret.status,
        'synced': 0,
      });
      // Insert each return item into return_items table
      for (final item in ret.items) {
        await DBHelper.insert('return_items', {
          'returnId': ret.id,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'originalPrice': item.originalPrice,
          'reason': item.reason,
          'shopId': ret.shopId,
          'synced': 0,
        });
      }
      notifyListeners();
      return;
    }
    await ApiService.post('returns', ret.toJson());
  }

  Future<void> syncReturnsToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('returns');
    for (final ret in unsynced) {
      await ApiService.post('returns', ret);
      await DBHelper.markAsSynced('returns', ret['id']);
    }
  }
}
