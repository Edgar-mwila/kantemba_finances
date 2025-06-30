import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class SalesProvider with ChangeNotifier {
  List<Sale> _sales = [];

  List<Sale> get sales => [..._sales];

  Future<void> fetchAndSetSales() async {
    final salesData = await DBHelper.getData('sales');
    final saleItemsData = await DBHelper.getData('sale_items');

    _sales =
        salesData.map((saleMap) {
          final relevantItems =
              saleItemsData
                  .where((itemMap) => itemMap['saleId'] == saleMap['id'])
                  .toList();
          return Sale(
            id: saleMap['id'],
            totalAmount: saleMap['totalAmount'],
            grandTotal: saleMap['grandTotal'],
            vat: saleMap['vat'],
            turnoverTax: saleMap['turnoverTax'],
            levy: saleMap['levy'],
            date: DateTime.parse(saleMap['date']),
            createdBy: saleMap['createdBy'],
            items:
                relevantItems
                    .map(
                      (itemMap) => SaleItem(
                        product: InventoryItem(
                          id: itemMap["id"],
                          name: itemMap['productName'],
                          price: itemMap['price'],
                          quantity: itemMap['quantity'],
                          createdBy: itemMap["createdBy"],
                        ),
                      ),
                    )
                    .toList(),
          );
        }).toList();

    notifyListeners();
  }

  Future<void> addSale(Sale sale, String createdBy) async {
    final newSale = Sale(
      id: DateTime.now().toString(),
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

    await DBHelper.insert('sales', {
      'id': newSale.id,
      'totalAmount': newSale.totalAmount,
      'grandTotal': newSale.grandTotal,
      'vat': newSale.vat,
      'turnoverTax': newSale.turnoverTax,
      'levy': newSale.levy,
      'date': newSale.date.toIso8601String(),
      'createdBy': createdBy,
    });

    for (var item in newSale.items) {
      await DBHelper.insert('sale_items', {
        'saleId': newSale.id,
        'productId': item.product.name, // Assuming name is unique for now
        'productName': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
      });
    }
  }
}
