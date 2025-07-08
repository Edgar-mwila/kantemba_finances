import 'package:kantemba_finances/models/inventory_item.dart';

class Sale {
  final String id;
  final List<SaleItem> items;
  final double totalAmount;
  final double grandTotal;
  final double vat;
  final double turnoverTax;
  final double levy;
  final DateTime date;
  final String shopId;
  final String createdBy;

  Sale({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.grandTotal,
    required this.vat,
    required this.turnoverTax,
    required this.levy,
    required this.date,
    required this.shopId,
    required this.createdBy,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      vat: (json['vat'] as num).toDouble(),
      turnoverTax: (json['turnoverTax'] as num).toDouble(),
      levy: (json['levy'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      shopId: json['shopId'] as String,
      items: <SaleItem>[],
      createdBy: json['createdBy'] as String,
    );
  }
}

class SaleItem {
  final InventoryItem product;
  int quantity;

  SaleItem({required this.product, this.quantity = 1});
}
