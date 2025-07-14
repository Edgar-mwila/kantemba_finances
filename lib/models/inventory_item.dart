class InventoryItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final int lowStockThreshold;
  final String shopId;
  final String createdBy;
  List<DamagedRecord> damagedRecords;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.lowStockThreshold = 5,
    required this.shopId,
    required this.createdBy,
    this.damagedRecords = const [],
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
      damagedRecords: (json['damagedRecords'] as List<dynamic>? ?? [])
        .map((e) => DamagedRecord.fromJson(e as Map<String, dynamic>)).toList(),
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
      'damagedRecords': damagedRecords.map((e) => e.toJson()).toList(),
    };
  }
}

class DamagedRecord {
  final int units;
  final String reason;
  final DateTime date;

  DamagedRecord({required this.units, required this.reason, required this.date});

  factory DamagedRecord.fromJson(Map<String, dynamic> json) => DamagedRecord(
    units: json['units'] as int,
    reason: json['reason'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
  );

  Map<String, dynamic> toJson() => {
    'units': units,
    'reason': reason,
    'date': date.toIso8601String(),
  };
}
