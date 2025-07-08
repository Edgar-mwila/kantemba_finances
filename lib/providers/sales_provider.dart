import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class SalesProvider with ChangeNotifier {
  List<Sale> _sales = [];

  List<Sale> get sales => [..._sales];

  // Get filtered sales based on ShopProvider.currentShop
  List<Sale> get filteredSales {
    // This will be accessed from the UI with ShopProvider context
    return _sales;
  }

  // Get all available shop IDs from sales
  List<String> get availableShopIds {
    return _sales.map((sale) => sale.shopId).toSet().toList();
  }

  // Get filtered sales based on current shop (to be used with ShopProvider)
  List<Sale> getSalesForShop(Shop? currentShop) {
    if (currentShop == null) {
      return _sales; // Show all sales when no shop is selected
    }
    return _sales.where((sale) => sale.shopId == currentShop.id).toList();
  }

  List<Sale> getSalesForShopAndDateRange(
    Shop? currentShop,
    DateTime? start,
    DateTime? end,
  ) {
    return getSalesForShop(currentShop).where((sale) {
      if (start != null && sale.date.isBefore(start)) return false;
      if (end != null && sale.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  Future<void> fetchAndSetSales(
    String businessId, {
    List<String>? shopIds,
  }) async {
    debugPrint(
      'fetchAndSetSales called with businessId: $businessId, shopIds: $shopIds',
    );
    List<Sale> allSales = [];
    List<dynamic> allSaleItems = [];

    try {
      if (shopIds != null && shopIds.isNotEmpty) {
        for (final shopId in shopIds) {
          await _fetchSalesForShop(businessId, shopId, allSales, allSaleItems);
        }
      } else {
        await _fetchAllSales(businessId, allSales, allSaleItems);
      }

      // Now map sales and sale items
      await _mapSalesAndItems(allSales, allSaleItems);
    } catch (e) {
      debugPrint('Error in fetchAndSetSales: $e');
    }
  }

  Future<void> _fetchSalesForShop(
    String businessId,
    String shopId,
    List<Sale> allSales,
    List<dynamic> allSaleItems,
  ) async {
    final query = 'sales?businessId=$businessId&shopId=$shopId';
    debugPrint('Fetching sales for shopId: $shopId with query: $query');

    try {
      final response1 = await ApiService.get(query);
      final response2 = await ApiService.get(
        'sale_items?businessId=$businessId&shopId=$shopId',
      );
      debugPrint('Sales response status: ${response1.statusCode}');
      debugPrint('Sale items response status: ${response2.statusCode}');

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        // Process sales data
        final salesData = _parseJsonResponse(response1.body, 'sales');
        if (salesData != null) {
          final salesDataList = _processSalesData(salesData);
          debugPrint('Sales data list length: ${salesDataList.length}');
          final salesObjects = _convertToSales(salesDataList);
          allSales.addAll(salesObjects);
        } else {
          debugPrint('No sales data found for shopId: $shopId');
        }

        // Process sale items data
        final saleItemsData = _parseJsonResponse(response2.body, 'sale_items');
        if (saleItemsData != null) {
          final saleItemsList = _processSaleItemsData(saleItemsData);
          debugPrint('Sale items data length: ${saleItemsList.length}');
          allSaleItems.addAll(saleItemsList);
        } else {
          debugPrint('No sale items data found for shopId: $shopId');
        }
      } else {
        debugPrint('Failed to fetch sales or sale items for shopId: $shopId');
      }
    } catch (e) {
      debugPrint('Error fetching data for shopId: $shopId, error: $e');
    }
  }

  Future<void> _fetchAllSales(
    String businessId,
    List<Sale> allSales,
    List<dynamic> allSaleItems,
  ) async {
    final query = 'sales?businessId=$businessId';
    debugPrint(
      'Fetching all sales for businessId: $businessId with query: $query',
    );

    try {
      final response1 = await ApiService.get(query);
      final response2 = await ApiService.get(
        'sale_items?businessId=$businessId',
      );
      debugPrint('Sales response status: ${response1.statusCode}');
      debugPrint('Sale items response status: ${response2.statusCode}');

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        // Process sales data
        final salesData = _parseJsonResponse(response1.body, 'sales');
        if (salesData != null) {
          final salesDataList = _processSalesData(salesData);
          debugPrint('Sales data list length: ${salesDataList.length}');
          final salesObjects = _convertToSales(salesDataList);
          allSales.addAll(salesObjects);
        } else {
          debugPrint('No sales data found for businessId: $businessId');
        }

        // Process sale items data
        final saleItemsData = _parseJsonResponse(response2.body, 'sale_items');
        if (saleItemsData != null) {
          final saleItemsList = _processSaleItemsData(saleItemsData);
          debugPrint('Sale items data length: ${saleItemsList.length}');
          allSaleItems.addAll(saleItemsList);
        } else {
          debugPrint('No sale items data found for businessId: $businessId');
        }
      } else {
        debugPrint(
          'Failed to fetch sales or sale items for businessId: $businessId',
        );
      }
    } catch (e) {
      debugPrint('Error fetching data for businessId: $businessId, error: $e');
    }
  }

  Future<void> _mapSalesAndItems(
    List<Sale> allSales,
    List<dynamic> allSaleItems,
  ) async {
    debugPrint('Mapping sales and sale items...');
    try {
      _sales =
          allSales.map((sale) {
            final relevantItems =
                allSaleItems
                    .where(
                      (itemMap) =>
                          itemMap != null && itemMap['saleId'] == sale.id,
                    )
                    .toList();
            debugPrint('Sale id: ${sale.id} has ${relevantItems.length} items');

            return Sale(
              id: sale.id,
              totalAmount: sale.totalAmount,
              grandTotal: sale.grandTotal,
              vat: sale.vat,
              turnoverTax: sale.turnoverTax,
              levy: sale.levy,
              date: sale.date,
              shopId: sale.shopId,
              createdBy: sale.createdBy,
              items:
                  relevantItems
                      .map((itemMap) => _createSaleItem(itemMap))
                      .where((item) => item != null)
                      .cast<SaleItem>()
                      .toList(),
            );
          }).toList();

      debugPrint('Total sales after mapping: ${_sales.length}');
      notifyListeners();
      debugPrint('Listeners notified.');
    } catch (e) {
      debugPrint('Error mapping sales and sale items: $e');
    }
  }

  // Helper method to convert dynamic list to Sale objects
  List<Sale> _convertToSales(List<dynamic> salesDataList) {
    final List<Sale> sales = [];
    for (final item in salesDataList) {
      try {
        if (item is Map<String, dynamic>) {
          final sale = Sale.fromJson(item);
          sales.add(sale);
        } else if (item is Map) {
          final sale = Sale.fromJson(Map<String, dynamic>.from(item));
          sales.add(sale);
        } else {
          debugPrint('Skipping invalid sale item: $item');
        }
      } catch (e) {
        debugPrint(
          'Error converting sale item to Sale object: $e, item: $item',
        );
      }
    }
    return sales;
  }

  // Helper method to parse JSON response
  dynamic _parseJsonResponse(String responseBody, String dataType) {
    try {
      if (responseBody.trim().isEmpty) {
        debugPrint('Empty response body for $dataType');
        return null;
      }

      final data = json.decode(responseBody);
      debugPrint('Decoded $dataType data: $data');

      // Handle the case where the API returns null
      if (data == null) {
        debugPrint('API returned null for $dataType');
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Error decoding $dataType data: $e');
      debugPrint('Response body: $responseBody');
      return null;
    }
  }

  // Helper method to process sales data
  List<dynamic> _processSalesData(dynamic data) {
    if (data == null) return [];

    try {
      if (data is List) {
        return data.where((item) => item != null && item is Map).toList();
      } else if (data is Map) {
        return [data];
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          var decoded = json.decode(data);
          if (decoded is List) {
            return decoded
                .where((item) => item != null && item is Map)
                .toList();
          } else if (decoded is Map) {
            return [decoded];
          }
        } catch (e) {
          debugPrint('Error decoding nested sales data: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing sales data: $e');
    }
    return [];
  }

  // Helper method to process sale items data
  List<dynamic> _processSaleItemsData(dynamic data) {
    if (data == null) return [];

    try {
      if (data is List) {
        return data.where((item) => item != null && item is Map).toList();
      } else if (data is Map) {
        return [data];
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          var decoded = json.decode(data);
          if (decoded is List) {
            return decoded
                .where((item) => item != null && item is Map)
                .toList();
          } else if (decoded is Map) {
            return [decoded];
          }
        } catch (e) {
          debugPrint('Error decoding nested sale items data: $e');
        }
      }
    } catch (e) {
      debugPrint('Error processing sale items data: $e');
    }
    return [];
  }

  // Helper method to create SaleItem safely
  SaleItem? _createSaleItem(dynamic itemMap) {
    try {
      if (itemMap == null) return null;

      return SaleItem(
        product: InventoryItem(
          id: itemMap["productId"]?.toString() ?? '',
          name: itemMap['productName']?.toString() ?? '',
          price: _parseDouble(itemMap['price']),
          quantity: _parseInt(itemMap['quantity']),
          shopId: itemMap['shopId']?.toString() ?? '',
          createdBy: '',
        ),
        quantity: _parseInt(itemMap['quantity']),
      );
    } catch (e) {
      debugPrint('Error creating SaleItem: $e, itemMap: $itemMap');
      return null;
    }
  }

  // Helper method to safely parse double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely parse int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> addSale(Sale sale, String createdBy, String shopId) async {
    final newSale = Sale(
      id: '${shopId}_${DateTime.now().toString()}',
      items: sale.items,
      totalAmount: sale.totalAmount,
      grandTotal: sale.grandTotal,
      vat: sale.vat,
      turnoverTax: sale.turnoverTax,
      levy: sale.levy,
      date: sale.date,
      createdBy: createdBy,
      shopId: shopId,
    );
    _sales.add(newSale);
    notifyListeners();

    await ApiService.post('sales', {
      'id': newSale.id,
      'totalAmount': newSale.totalAmount,
      'grandTotal': newSale.grandTotal,
      'vat': newSale.vat,
      'turnoverTax': newSale.turnoverTax,
      'levy': newSale.levy,
      'date': newSale.date.toIso8601String(),
      'createdBy': newSale.createdBy,
      'shopId': shopId,
    });

    for (var item in newSale.items) {
      await ApiService.post('sale_items', {
        'saleId': newSale.id,
        'productId': item.product.id,
        'productName': item.product.name,
        'price': (item.product.price as num).toDouble(),
        'quantity': item.quantity,
        'shopId': shopId,
      });
    }
  }

  Future<void> fetchAndSetSalesHybrid(BusinessProvider businessProvider) async {
    if (!businessProvider.isPremium) {
      // Local only
      final localSales = await DBHelper.getData('sales');
      _sales = localSales.map((item) => Sale.fromJson(item)).toList();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      // Online fetch
      await fetchAndSetSales(businessProvider.id!);
    } else {
      // Offline, use local DB
      final localSales = await DBHelper.getData('sales');
      _sales = localSales.map((item) => Sale.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> addSaleHybrid(
    Sale sale,
    String createdBy,
    String shopId,
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      // Local only or offline: save to local DB, mark as unsynced
      await DBHelper.insert('sales', {
        'id': sale.id,
        'items': jsonEncode(sale.items.map((item) => item).toList()),
        'totalAmount': sale.totalAmount,
        'grandTotal': sale.grandTotal,
        'vat': sale.vat,
        'turnoverTax': sale.turnoverTax,
        'levy': sale.levy,
        'date': sale.date.toIso8601String(),
        'createdBy': createdBy,
        'shopId': shopId,
        'synced': 0,
      });
      _sales.add(sale);
      notifyListeners();
      return;
    }
    // Online: save to backend
    await addSale(sale, createdBy, shopId);
    // Optionally, mark as synced in local DB
  }

  Future<void> syncSalesToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('sales');
    for (final sale in unsynced) {
      await ApiService.post('sales', sale);
      await DBHelper.markAsSynced('sales', sale['id']);
    }
  }
}
