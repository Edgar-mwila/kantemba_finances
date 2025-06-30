import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';

class InventoryBookScreen extends StatelessWidget {
  const InventoryBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Provider.of<InventoryProvider>(context).items;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Book')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: ListTile(
            title: Text(items[i].name),
            subtitle: Text('Price: K${items[i].price.toStringAsFixed(2)}'),
            trailing: Text('Stock: ${items[i].quantity}'),
          ),
        ),
      ),
    );
  }
} 