import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
// import 'package:kantemba_finances/models/inventory_item.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final items = inventoryData.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory'), centerTitle: true),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder:
            (ctx, i) => ListTile(
              title: Text(items[i].name),
              subtitle: Text('Price: K${items[i].price.toStringAsFixed(2)}'),
              trailing: Text('Stock: ${items[i].quantity}'),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show a modal to add a new inventory item
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
