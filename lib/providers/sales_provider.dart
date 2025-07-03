import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/sale.dart';

class SalesProvider with ChangeNotifier {
  List<Sale> _sales = [];

  List<Sale> get sales => [..._sales];

  Future<void> fetchAndSetSales(String businessId) async {
    final response1 = await ApiService.get('sales?businessId=$businessId');
    final response2 = await ApiService.get('sale_items?businessId=$businessId');
    if (response1.statusCode != 200 || response2.statusCode != 200) {
      //Return some error
    }
    if (kDebugMode) {
      print('Sales API response: ${response1.body}');
      print('Sale_items API response: ${response2.body}');
    }
    dynamic data = json.decode(response1.body);
    List<dynamic> salesDataList;

    if (data is List) {
      salesDataList = data;
    } else if (data is Map) {
      salesDataList = [data];
    } else if (data is String && data.trim().isNotEmpty) {
      // Try to decode again if it's a JSON string
      var decoded = json.decode(data);
      if (decoded is List) {
        salesDataList = decoded;
      } else if (decoded is Map) {
        salesDataList = [decoded];
      } else {
        salesDataList = [];
      }
    } else {
      salesDataList = [];
    }

    dynamic data1 = json.decode(response2.body);
    List<dynamic> saleItemsData;

    if (data1 is List) {
      saleItemsData = data1;
    } else if (data1 is Map) {
      saleItemsData = [data1];
    } else if (data1 is String && data1.trim().isNotEmpty) {
      // Try to decode again if it's a JSON string
      var decoded = json.decode(data1);
      if (decoded is List) {
        saleItemsData = decoded;
      } else if (decoded is Map) {
        saleItemsData = [decoded];
      } else {
        saleItemsData = [];
      }
    } else {
      saleItemsData = [];
    }
    _sales =
        salesDataList.map((saleMap) {
          final relevantItems =
              saleItemsData
                  .where((itemMap) => itemMap['saleId'] == saleMap['id'])
                  .toList();
          return Sale(
            id: saleMap['id'],
            totalAmount: (saleMap['totalAmount'] as num).toDouble(),
            grandTotal: (saleMap['grandTotal'] as num).toDouble(),
            vat: (saleMap['vat'] as num).toDouble(),
            turnoverTax: (saleMap['turnoverTax'] as num).toDouble(),
            levy: (saleMap['levy'] as num).toDouble(),
            date: DateTime.parse(saleMap['date']),
            createdBy: saleMap['createdBy'],
            items:
                relevantItems
                    .map(
                      (itemMap) => SaleItem(
                        product: InventoryItem(
                          id: itemMap["productId"],
                          name: itemMap['productName'],
                          price: (itemMap['price'] as num).toDouble(),
                          quantity: itemMap['quantity'],
                          createdBy: '', // Not tracked in sale_items
                        ),
                        quantity: itemMap['quantity'],
                      ),
                    )
                    .toList(),
          );
        }).toList();

    notifyListeners();
  }

  Future<void> addSale(Sale sale, String businessId, String createdBy) async {
    final newSale = Sale(
      id: '${businessId}_${DateTime.now().toString()}',
      items: sale.items,
      totalAmount: sale.totalAmount,
      grandTotal: sale.grandTotal,
      vat: sale.vat,
      turnoverTax: sale.turnoverTax,
      levy: sale.levy,
      date: sale.date,
      createdBy: createdBy,
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
      'businessId': businessId,
      'createdBy': newSale.createdBy,
    });

    for (var item in newSale.items) {
      await ApiService.post('sale_items', {
        'saleId': newSale.id,
        'productId': item.product.id, // Use the actual product ID
        'productName': item.product.name,
        'price': (item.product.price as num).toDouble(),
        'quantity': item.quantity,
      });
    }
  }
}
