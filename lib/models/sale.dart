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
    required this.createdBy,
  });
}

class SaleItem {
  final InventoryItem product;
  int quantity;

  SaleItem({required this.product, this.quantity = 1});
}
