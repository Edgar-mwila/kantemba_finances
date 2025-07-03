import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/widgets/new_sale_modal.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final sales = salesData.sales;

    return Scaffold(
      body: ListView.builder(
        itemCount: sales.length,
        itemBuilder:
            (ctx, i) => ListTile(
              title: Text('Sale ID: ${sales[i].id}'),
              subtitle: Text(sales[i].date.toIso8601String()),
              trailing: Text('K${sales[i].grandTotal.toStringAsFixed(2)}'),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) {
                    final sale = sales[i];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ...sale.items.map<Widget>(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(item.product.name)),
                                  Text(
                                    '${item.quantity} x K${item.product.price.toStringAsFixed(2)}',
                                  ),
                                  Text(
                                    '= K${(item.quantity * item.product.price).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'K${sale.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const NewSaleModal(),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
