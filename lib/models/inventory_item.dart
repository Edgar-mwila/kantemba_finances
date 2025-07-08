class InventoryItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final int lowStockThreshold;
  final String shopId;
  final String createdBy;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.lowStockThreshold = 5,
    required this.shopId,
    required this.createdBy,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
      shopId: json['shopId'] as String,
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'shopId': shopId,
      'createdBy': createdBy,
    };
  }
}
