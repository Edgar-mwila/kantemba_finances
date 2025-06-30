import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';

class SalesBookScreen extends StatelessWidget {
  const SalesBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = Provider.of<SalesProvider>(context).sales;

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Book')),
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: ListTile(
            title: Text('Sale ID: ${sales[i].id}'),
            subtitle: Text(
                'Items: ${sales[i].items.length} | Date: ${sales[i].date.toIso8601String().split('T')[0]}'),
            trailing: Text('K${sales[i].grandTotal.toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }
} 