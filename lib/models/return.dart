import 'package:kantemba_finances/models/inventory_item.dart';

class Return {
  final String id;
  final String originalSaleId;
  final List<ReturnItem> items;
  final double totalReturnAmount;
  final double grandReturnAmount;
  final double vat;
  final double turnoverTax;
  final double levy;
  final DateTime date;
  final String shopId;
  final String createdBy;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'completed'

  Return({
    required this.id,
    required this.originalSaleId,
    required this.items,
    required this.totalReturnAmount,
    required this.grandReturnAmount,
    required this.vat,
    required this.turnoverTax,
    required this.levy,
    required this.date,
    required this.shopId,
    required this.createdBy,
    required this.reason,
    required this.status,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      id: json['id'] as String,
      originalSaleId: json['originalSaleId'] as String,
      totalReturnAmount: (json['totalReturnAmount'] as num).toDouble(),
      grandReturnAmount: (json['grandReturnAmount'] as num).toDouble(),
      vat: (json['vat'] as num).toDouble(),
      turnoverTax: (json['turnoverTax'] as num).toDouble(),
      levy: (json['levy'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      shopId: json['shopId'] as String,
      createdBy: json['createdBy'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      items: <ReturnItem>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalSaleId': originalSaleId,
      'totalReturnAmount': totalReturnAmount,
      'grandReturnAmount': grandReturnAmount,
      'vat': vat,
      'turnoverTax': turnoverTax,
      'levy': levy,
      'date': date.toIso8601String(),
      'shopId': shopId,
      'createdBy': createdBy,
      'reason': reason,
      'status': status,
    };
  }
}

class ReturnItem {
  final InventoryItem product;
  int quantity;
  final double originalPrice;
  final String reason;

  ReturnItem({
    required this.product,
    required this.quantity,
    required this.originalPrice,
    required this.reason,
  });

  double get totalAmount => originalPrice * quantity;

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      product: InventoryItem.fromJson(json['product']),
      quantity: json['quantity'] as int,
      originalPrice: (json['originalPrice'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'originalPrice': originalPrice,
      'reason': reason,
    };
  }
}
