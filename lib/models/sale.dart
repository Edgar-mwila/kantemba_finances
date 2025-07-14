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
  final String? customerName;
  final String? customerPhone;
  final double discount;

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
    this.customerName,
    this.customerPhone,
    this.discount = 0.0,
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
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'grandTotal': grandTotal,
    'vat': vat,
    'turnoverTax': turnoverTax,
    'levy': levy,
    'date': date.toIso8601String(),
    'shopId': shopId,
    'createdBy': createdBy,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'discount': discount,
  };
}

class SaleItem {
  final InventoryItem product;
  int quantity;
  int returnedQuantity;
  String returnedReason;

  SaleItem({
    required this.product, 
    this.quantity = 1,
    this.returnedQuantity = 0,
    this.returnedReason = '',
  });

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'returnedQuantity': returnedQuantity,
    'returnedReason': returnedReason,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      product: InventoryItem.fromJson(json['product']),
      quantity: json['quantity'] as int? ?? 1,
      returnedQuantity: json['returnedQuantity'] as int? ?? 0,
      returnedReason: json['returnedReason'] as String? ?? '',
    );
  }
}
