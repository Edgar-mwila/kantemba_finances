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
    bool isOnline = await ApiService.isOnline();
    final business = await DBHelper.getDataById('businesses', businessId);
    final isPremium = business?['isPremium'] == 1;

    if (!isOnline || !isPremium) {
      // Offline mode or non-premium business: load from local database
      try {
        final localSales = await DBHelper.getDataByBusinessId(
          'sales',
          businessId,
        );
        final localSaleItems = await DBHelper.getData('sale_items');
        final localReturnItems = await DBHelper.getData('return_items');
        final localReturns = await DBHelper.getDataByBusinessId(
          'returns',
          businessId,
        );

        _sales = localSales.map((item) => Sale.fromJson(item)).toList();

        // Store returns data for mapping in offline mode
        _returnsData = localReturns;

        await _mapSalesAndItems(_sales, localSaleItems, localReturnItems);

        notifyListeners();
        return;
      } catch (e) {
        _sales = [];
        notifyListeners();
        return;
      }
    }

    // Online mode and premium business: fetch from API
    List<Sale> allSales = [];
    List<dynamic> allSaleItems = [];
    List<dynamic> allReturnItems = [];

    try {
      if (shopIds != null && shopIds.isNotEmpty) {
        for (final shopId in shopIds) {
          await _fetchSalesForShop(
            businessId,
            shopId,
            allSales,
            allSaleItems,
            allReturnItems,
          );
        }
      } else {
        await _fetchAllSales(
          businessId,
          allSales,
          allSaleItems,
          allReturnItems,
        );
      }

      // Now map sales and sale items
      await _mapSalesAndItems(allSales, allSaleItems, allReturnItems);
    } catch (e) {}
  }

  Future<void> _fetchSalesForShop(
    String businessId,
    String shopId,
    List<Sale> allSales,
    List<dynamic> allSaleItems,
    List<dynamic> allReturnItems,
  ) async {
    final query = 'sales?businessId=$businessId&shopId=$shopId';

    try {
      final response1 = await ApiService.get(query);
      final response2 = await ApiService.get(
        'sale_items?businessId=$businessId&shopId=$shopId',
      );
      final response3 = await ApiService.get(
        'return_items?businessId=$businessId&shopId=$shopId',
      );
      final response4 = await ApiService.get(
        'returns?businessId=$businessId&shopId=$shopId',
      );

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        // Process sales data
        final salesData = _parseJsonResponse(response1.body, 'sales');
        if (salesData != null) {
          final salesDataList = _processSalesData(salesData);
          final salesObjects = _convertToSales(salesDataList);
          allSales.addAll(salesObjects);
        } else {}

        // Process sale items data
        final saleItemsData = _parseJsonResponse(response2.body, 'sale_items');
        if (saleItemsData != null) {
          final saleItemsList = _processSaleItemsData(saleItemsData);
          allSaleItems.addAll(saleItemsList);
        } else {}

        // Process return items data
        if (response3.statusCode == 200) {
          final returnItemsData = _parseJsonResponse(
            response3.body,
            'return_items',
          );
          if (returnItemsData != null) {
            final returnItemsList = _processReturnItemsData(returnItemsData);
            allReturnItems.addAll(returnItemsList);
          } else {}
        } else {}

        // Process returns data to get originalSaleId mapping
        if (response4.statusCode == 200) {
          final returnsData = _parseJsonResponse(response4.body, 'returns');
          if (returnsData != null) {
            final returnsList = _processReturnsData(returnsData);
            // Store returns data for mapping
            _returnsData = returnsList;
          } else {}
        } else {}
      } else {}
    } catch (e) {}
  }

  Future<void> _fetchAllSales(
    String businessId,
    List<Sale> allSales,
    List<dynamic> allSaleItems,
    List<dynamic> allReturnItems,
  ) async {
    final query = 'sales?businessId=$businessId';

    try {
      final response1 = await ApiService.get(query);
      final response2 = await ApiService.get(
        'sale_items?businessId=$businessId',
      );
      final response3 = await ApiService.get(
        'return_items?businessId=$businessId',
      );
      final response4 = await ApiService.get('returns?businessId=$businessId');

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        // Process sales data
        final salesData = _parseJsonResponse(response1.body, 'sales');
        if (salesData != null) {
          final salesDataList = _processSalesData(salesData);
          final salesObjects = _convertToSales(salesDataList);
          allSales.addAll(salesObjects);
        } else {}

        // Process sale items data
        final saleItemsData = _parseJsonResponse(response2.body, 'sale_items');
        if (saleItemsData != null) {
          final saleItemsList = _processSaleItemsData(saleItemsData);
          allSaleItems.addAll(saleItemsList);
        } else {}

        // Process return items data
        if (response3.statusCode == 200) {
          final returnItemsData = _parseJsonResponse(
            response3.body,
            'return_items',
          );
          if (returnItemsData != null) {
            final returnItemsList = _processReturnItemsData(returnItemsData);
            allReturnItems.addAll(returnItemsList);
          } else {}
        } else {}

        // Process returns data to get originalSaleId mapping
        if (response4.statusCode == 200) {
          final returnsData = _parseJsonResponse(response4.body, 'returns');
          if (returnsData != null) {
            final returnsList = _processReturnsData(returnsData);
            // Store returns data for mapping
            _returnsData = returnsList;
          } else {}
        } else {}
      } else {}
    } catch (e) {}
  }

  // Store returns data for mapping
  List<dynamic> _returnsData = [];

  Future<void> _mapSalesAndItems(
    List<Sale> allSales,
    List<dynamic> allSaleItems,
    List<dynamic> allReturnItems,
  ) async {
    try {
      // Create a map of return items by original sale ID and product ID for quick lookup
      final Map<String, Map<String, dynamic>> returnItemsBySaleAndProduct = {};

      // First, create a map of returnId to originalSaleId from returns data
      final Map<String, String> returnIdToOriginalSaleId = {};
      for (final returnData in _returnsData) {
        if (returnData != null &&
            returnData['id'] != null &&
            returnData['originalSaleId'] != null) {
          returnIdToOriginalSaleId[returnData['id'] as String] =
              returnData['originalSaleId'] as String;
        }
      }

      // Now map return items to their original sales
      for (final returnItem in allReturnItems) {
        if (returnItem != null && returnItem['returnId'] != null) {
          final returnId = returnItem['returnId'] as String;
          final originalSaleId = returnIdToOriginalSaleId[returnId];

          if (originalSaleId != null) {
            final productId = returnItem['productId'] as String;

            if (!returnItemsBySaleAndProduct.containsKey(originalSaleId)) {
              returnItemsBySaleAndProduct[originalSaleId] = {};
            }
            returnItemsBySaleAndProduct[originalSaleId]![productId] =
                returnItem;
          }
        }
      }

      _sales =
          allSales.map((sale) {
            final relevantItems =
                allSaleItems
                    .where(
                      (itemMap) =>
                          itemMap != null && itemMap['saleId'] == sale.id,
                    )
                    .toList();

            final saleItems =
                relevantItems
                    .map(
                      (itemMap) =>
                          _createSaleItem(itemMap, returnItemsBySaleAndProduct),
                    )
                    .where((item) => item != null)
                    .cast<SaleItem>()
                    .toList();

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
              customerName: sale.customerName,
              customerPhone: sale.customerPhone,
              discount: sale.discount,
              items: saleItems,
            );
          }).toList();

      notifyListeners();
    } catch (e) {}
  }

  // Helper method to process returns data
  List<dynamic> _processReturnsData(dynamic data) {
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
        } catch (e) {}
      }
    } catch (e) {}
    return [];
  }

  // Helper method to process return items data
  List<dynamic> _processReturnItemsData(dynamic data) {
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
        } catch (e) {}
      }
    } catch (e) {}
    return [];
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
        } else {}
      } catch (e) {}
    }
    return sales;
  }

  // Helper method to parse JSON response
  dynamic _parseJsonResponse(String responseBody, String dataType) {
    try {
      if (responseBody.trim().isEmpty) {
        return null;
      }

      final data = json.decode(responseBody);

      // Handle the case where the API returns null
      if (data == null) {
        return null;
      }

      return data;
    } catch (e) {
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
        } catch (e) {}
      }
    } catch (e) {}
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
        } catch (e) {}
      }
    } catch (e) {}
    return [];
  }

  // Helper method to create SaleItem safely with return information
  SaleItem? _createSaleItem(
    dynamic itemMap,
    Map<String, Map<String, dynamic>> returnItemsBySaleAndProduct,
  ) {
    try {
      if (itemMap == null) return null;

      final saleId = itemMap["saleId"]?.toString() ?? '';
      final productId = itemMap["productId"]?.toString() ?? '';

      // Get returned quantity and reason from database first
      int returnedQuantity = _parseInt(itemMap['returnedQuantity']);
      String returnedReason = itemMap['returnedReason']?.toString() ?? '';

      // If not in database, look for return items that match this sale and product
      if (returnedQuantity == 0 && returnedReason.isEmpty) {
        final returnItemsForSale = returnItemsBySaleAndProduct[saleId];
        if (returnItemsForSale != null &&
            returnItemsForSale.containsKey(productId)) {
          final returnItem = returnItemsForSale[productId];
          returnedQuantity = _parseInt(returnItem['quantity']);
          returnedReason = returnItem['reason']?.toString() ?? '';
        }
      }

      return SaleItem(
        product: InventoryItem(
          id: productId,
          name: itemMap['productName']?.toString() ?? '',
          price: _parseDouble(itemMap['price']),
          quantity: _parseInt(itemMap['quantity']),
          shopId: itemMap['shopId']?.toString() ?? '',
          createdBy: '',
        ),
        quantity: _parseInt(itemMap['quantity']),
        returnedQuantity: returnedQuantity,
        returnedReason: returnedReason,
      );
    } catch (e) {
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
      discount: sale.discount,
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
      'date': sale.date.toIso8601String(),
      'createdBy': newSale.createdBy,
      'shopId': shopId,
      if (newSale.customerName != null) 'customerName': newSale.customerName,
      if (newSale.customerPhone != null) 'customerPhone': newSale.customerPhone,
      'discount': newSale.discount,
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
      final localSales = await DBHelper.getDataByBusinessId(
        'sales',
        businessProvider.id!,
      );
      final localSaleItems = await DBHelper.getData('sale_items');
      final localReturnItems = await DBHelper.getData('return_items');
      final localReturns = await DBHelper.getDataByBusinessId(
        'returns',
        businessProvider.id!,
      );

      _sales = localSales.map((item) => Sale.fromJson(item)).toList();
      _returnsData = localReturns;

      await _mapSalesAndItems(_sales, localSaleItems, localReturnItems);
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      // Online fetch
      await fetchAndSetSales(businessProvider.id!);
    } else {
      // Offline, use local DB
      final localSales = await DBHelper.getDataByBusinessId(
        'sales',
        businessProvider.id!,
      );
      final localSaleItems = await DBHelper.getData('sale_items');
      final localReturnItems = await DBHelper.getData('return_items');
      final localReturns = await DBHelper.getDataByBusinessId(
        'returns',
        businessProvider.id!,
      );

      _sales = localSales.map((item) => Sale.fromJson(item)).toList();
      _returnsData = localReturns;

      await _mapSalesAndItems(_sales, localSaleItems, localReturnItems);
      notifyListeners();
    }
  }

  Future<void> addSaleHybrid(
    Sale sale,
    String createdBy,
    String shopId,
    BusinessProvider businessProvider,
  ) async {
    print("sale being added: ${sale.toJson()}");
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('sales', {
        'id': sale.id,
        'totalAmount': sale.totalAmount,
        'grandTotal': sale.grandTotal,
        'vat': sale.vat,
        'turnoverTax': sale.turnoverTax,
        'levy': sale.levy,
        'date': sale.date.toIso8601String(),
        'createdBy': createdBy,
        'shopId': shopId,
        'synced': 0,
        'customerName': sale.customerName ?? '',
        'customerPhone': sale.customerPhone ?? '',
        'discount': sale.discount,
      });
      // Insert each sale item into sale_items table
      for (final item in sale.items) {
        await DBHelper.insert('sale_items', {
          'saleId': sale.id,
          'productId': item.product.id,
          'productName': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'returnedQuantity': item.returnedQuantity,
          'returnedReason': item.returnedReason,
          'shopId': shopId,
          'synced': 0,
        });
      }
      _sales.add(sale);
      notifyListeners();
      return;
    }
    // Online: save to backend
    await addSale(sale, createdBy, shopId);
    // Optionally, mark as synced in local DB
  }

  Future<void> updateSaleItemsFromReturn(
    String saleId,
    List<ReturnItem> returnItems,
  ) async {
    final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);
    if (saleIndex == -1) {
      return;
    }

    final sale = _sales[saleIndex];
    print('sale to be updated: ${sale.toJson()}');
    final businessProvider = BusinessProvider();

    // Calculate total return amount
    final totalReturnAmount = returnItems.fold(
      0.0,
      (sum, item) => sum + (item.originalPrice * item.quantity),
    );

    // Update sale items with returned quantities
    final updatedItems =
        sale.items.map((saleItem) {
          final returnItem = returnItems.firstWhere(
            (item) => item.product.id == saleItem.product.id,
            orElse:
                () => ReturnItem(
                  product: saleItem.product,
                  quantity: 0,
                  originalPrice: saleItem.product.price,
                  reason: '',
                ),
          );

          return SaleItem(
            product: saleItem.product,
            quantity: saleItem.quantity,
            returnedQuantity: returnItem.quantity,
            returnedReason: returnItem.reason,
          );
        }).toList();

    // Create updated sale
    final updatedSale = Sale(
      id: sale.id,
      items: updatedItems,
      totalAmount: sale.totalAmount - totalReturnAmount,
      grandTotal: sale.grandTotal - totalReturnAmount,
      vat: sale.vat,
      turnoverTax: sale.turnoverTax,
      levy: sale.levy,
      date: sale.date,
      shopId: sale.shopId,
      createdBy: sale.createdBy,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      discount: sale.discount,
    );

    print('Updated sale: ${updatedSale.toJson()}');

    // Update in memory
    _sales[saleIndex] = updatedSale;

    // Update in database
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      // Update sale totals
      await DBHelper.update('sales', {
        'id': sale.id,
        'totalAmount': updatedSale.totalAmount,
        'grandTotal': updatedSale.grandTotal,
        'vat': sale.vat,
        'turnoverTax': sale.turnoverTax,
        'levy': sale.levy,
        'date': sale.date.toIso8601String(),
        'createdBy': sale.createdBy,
        'shopId': sale.shopId,
        'customerName': sale.customerName ?? '',
        'customerPhone': sale.customerPhone ?? '',
        'discount': sale.discount,
        'synced': 0,
      }, sale.id);

      // Update individual sale items with returned quantities
      for (final item in updatedItems) {
        // Find the existing sale item record to update
        final existingItems = await DBHelper.getData('sale_items');
        final existingItem = existingItems.firstWhere(
          (dbItem) =>
              dbItem['saleId'] == sale.id &&
              dbItem['productId'] == item.product.id,
          orElse: () => {},
        );

        if (existingItem.isNotEmpty) {
          await DBHelper.update('sale_items', {
            'saleId': sale.id,
            'productId': item.product.id,
            'productName': item.product.name,
            'price': item.product.price,
            'quantity': item.quantity,
            'returnedQuantity': item.returnedQuantity,
            'returnedReason': item.returnedReason,
            'shopId': sale.shopId,
            'synced': 0,
          }, existingItem['id'].toString());
        }
      }
    } else {
      // Online mode - update via API
      await ApiService.put('sales/${sale.id}', {
        'totalAmount': updatedSale.totalAmount,
        'grandTotal': updatedSale.grandTotal,
        'vat': sale.vat,
        'turnoverTax': sale.turnoverTax,
        'levy': sale.levy,
        'date': sale.date.toIso8601String(),
        'createdBy': sale.createdBy,
        'shopId': sale.shopId,
        'customerName': sale.customerName ?? '',
        'customerPhone': sale.customerPhone ?? '',
        'discount': sale.discount,
      });

      // Update sale items via API
      for (final item in updatedItems) {
        await ApiService.put('sale_items/${item.product.id}', {
          'saleId': sale.id,
          'productId': item.product.id,
          'productName': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'returnedQuantity': item.returnedQuantity,
          'returnedReason': item.returnedReason,
          'shopId': sale.shopId,
        });
      }
    }

    notifyListeners();
  }
}
