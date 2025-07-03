class InventoryItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final int lowStockThreshold;
  final String createdBy;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.lowStockThreshold = 5,
    required this.createdBy,
  });
}
