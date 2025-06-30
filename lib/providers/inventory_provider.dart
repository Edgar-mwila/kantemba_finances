import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];

  List<InventoryItem> get items => [..._items];

  Future<void> fetchAndSetItems() async {
    final dataList = await DBHelper.getData('inventory');
    _items = dataList
        .map(
          (item) => InventoryItem(
            id: item['id'],
            name: item['name'],
            price: item['price'],
            quantity: item['quantity'],
            lowStockThreshold: item['lowStockThreshold'],
            createdBy: item['createdBy'],
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> addInventoryItem(InventoryItem item, String createdBy) async {
    final newItem = InventoryItem(
      id: DateTime.now().toString(),
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      lowStockThreshold: item.lowStockThreshold,
      createdBy: createdBy,
    );
    _items.add(newItem);
    notifyListeners();

    await DBHelper.insert('inventory', {
      'id': newItem.id,
      'name': newItem.name,
      'price': newItem.price,
      'quantity': newItem.quantity,
      'lowStockThreshold': newItem.lowStockThreshold,
      'createdBy': createdBy,
    });
  }

  Future<void> updateStock(String productId, int quantitySold) async {
    final itemIndex = _items.indexWhere((item) => item.id == productId);
    if (itemIndex >= 0) {
      final item = _items[itemIndex];
      final newQuantity = item.quantity - quantitySold;
      final updatedItem = InventoryItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: newQuantity,
        lowStockThreshold: item.lowStockThreshold,
        createdBy: item.createdBy,
      );
      _items[itemIndex] = updatedItem;
      notifyListeners();

      await DBHelper.update('inventory', {'quantity': newQuantity}, item.id);
    }
  }
}
