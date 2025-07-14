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
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:provider/provider.dart';

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
    // Check if online and if business is premium
    bool isOnline = await ApiService.isOnline();
    final businessProvider = BusinessProvider();
    bool isPremium = businessProvider.isPremium;

    if (!isOnline || !isPremium) {
      // Offline mode or non-premium business: load from local database
      debugPrint(
        'ReturnsProvider: Loading returns from local database (offline: ${!isOnline}, premium: $isPremium)',
      );
      try {
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
        debugPrint(
          'ReturnsProvider: Loaded ${_returns.length} returns from local database',
        );
        return;
      } catch (e) {
        debugPrint('Error loading returns from local database: $e');
        _returns = [];
        notifyListeners();
        return;
      }
    }

    // Online mode and premium business: fetch from API
    debugPrint('ReturnsProvider: Loading returns from API');
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

      // Add return to local list
      _returns.add(ret);
      notifyListeners();
      return;
    }
    await ApiService.post('returns', ret.toJson());
  }

  Future<void> createReturn(
    Sale originalSale,
    List<ReturnItem> returnItems,
    String reason,
    String createdBy,
    String shopId,
    BuildContext context,
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

      // Save return to database
      final businessProvider = Provider.of<BusinessProvider>(
        context,
        listen: false,
      );
      await addReturnHybrid(newReturn, businessProvider);

      // Update inventory and sales based on return reasons
      await _updateInventoryAndSalesForReturn(
        returnItems,
        originalSale,
        reason,
        context,
      );
    } catch (e) {
      debugPrint('Error creating return: $e');
      rethrow;
    }
  }

  Future<void> _updateInventoryAndSalesForReturn(
    List<ReturnItem> returnItems,
    Sale originalSale,
    String reason,
    BuildContext context,
  ) async {
    try {
      final inventoryProvider = Provider.of<InventoryProvider>(
        context,
        listen: false,
      );
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      final isDamagedGoods =
          reason.toLowerCase().contains('damaged') ||
          reason.toLowerCase().contains('defective') ||
          reason.toLowerCase().contains('spoiled');

      // Update inventory quantities
      for (final returnItem in returnItems) {
        try {
          debugPrint(
            'Processing return item: ${returnItem.product.name} (ID: ${returnItem.product.id}) - ${returnItem.quantity} units',
          );

          final inventoryItem = inventoryProvider.items.firstWhere(
            (item) => item.id == returnItem.product.id,
            orElse: () => returnItem.product,
          );

          await inventoryProvider.reimburseStockForReturn(
            inventoryItem.id,
            returnItem.quantity,
          );

          if (isDamagedGoods) {
            // For damaged goods, reduce inventory and mark as damaged
            debugPrint(
              'Processing damaged goods return: ${returnItem.product.name} - ${returnItem.quantity} units',
            );
            inventoryProvider.decreaseStockForDamagedGoods(
              inventoryItem.id,
              returnItem.quantity,
              reason,
            );
          }
        } catch (e) {
          debugPrint(
            'Failed to update inventory for ${returnItem.product.name}: $e',
          );
          // Continue with other items even if one fails
        }
      }

      // Update sales - mark returned items and update database
      try {
        debugPrint('Updating sales for return...');
        await salesProvider.updateSaleItemsFromReturn(
          originalSale.id,
          returnItems,
        );
        debugPrint('Sales updated successfully');
      } catch (e) {
        debugPrint('Failed to update sales for return: $e');
      }

      debugPrint('Inventory and sales updated for return');
    } catch (e) {
      debugPrint('Error updating inventory and sales for return: $e');
      rethrow; // Re-throw to be handled by the calling function
    }
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
