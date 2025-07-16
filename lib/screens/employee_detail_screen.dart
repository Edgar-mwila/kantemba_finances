import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final User user;
  const EmployeeDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final expensesProvider = Provider.of<ExpensesProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final returnsProvider = Provider.of<ReturnsProvider>(context);

    final userSales =
        salesProvider.sales.where((sale) => sale.createdBy == user.id).toList();
    final userExpenses =
        expensesProvider.expenses
            .where((exp) => exp.createdBy == user.id)
            .toList();
    final userDamages = <Map<String, dynamic>>[];
    for (final item in inventoryProvider.items.where(
      (item) => item.createdBy == user.id,
    )) {
      for (final record in item.damagedRecords) {
        userDamages.add({'item': item, 'record': record});
      }
    }
    final userReturns =
        returnsProvider.returns
            .where((ret) => ret.createdBy == user.id)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text('${user.name} - Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sales', style: Theme.of(context).textTheme.titleLarge),
          if (userSales.isEmpty) const Text('No sales recorded.'),
          ...userSales.map(
            (sale) => Card(
              child: ListTile(
                title: Text('Sale: ${sale.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: K${sale.grandTotal.toStringAsFixed(2)}'),
                    if (sale.discount > 0)
                      Text(
                        'Discount: K${sale.discount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    Text('Date: ${sale.date.toLocal()}'.split(' ')[0]),
                    if (sale.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Items: ' +
                              sale.items
                                  .map(
                                    (item) =>
                                        '${item.product.name} x${item.quantity}',
                                  )
                                  .join(', '),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Expenses', style: Theme.of(context).textTheme.titleLarge),
          if (userExpenses.isEmpty) const Text('No expenses recorded.'),
          ...userExpenses.map(
            (exp) => Card(
              child: ListTile(
                title: Text(exp.description),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: K${exp.amount.toStringAsFixed(2)}'),
                    Text('Category: ${exp.category}'),
                    Text('Date: ${exp.date.toLocal()}'.split(' ')[0]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discounts Given',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (userSales.every((sale) => (sale.discount) == 0.0))
            const Text('No discounts given.'),
          ...userSales
              .where((sale) => (sale.discount) > 0)
              .map(
                (sale) => Card(
                  child: ListTile(
                    title: Text('Sale: ${sale.id}'),
                    subtitle: Text(
                      'Discount: K${sale.discount.toStringAsFixed(2)}',
                    ),
                    trailing: Text('${sale.date.toLocal()}'.split(' ')[0]),
                  ),
                ),
              ),
          const SizedBox(height: 24),
          Text(
            'Damages Reported',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (userDamages.isEmpty) const Text('No damages reported.'),
          ...userDamages.map(
            (data) => Card(
              child: ListTile(
                title: Text('Item: ${data['item'].name}'),
                subtitle: Text(
                  'Units: ${data['record'].units}, Reason: ${data['record'].reason}',
                ),
                trailing: Text(
                  '${data['record'].date.toLocal()}'.split(' ')[0],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Returns Processed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (userReturns.isEmpty) const Text('No returns processed.'),
          ...userReturns.map(
            (ret) => Card(
              child: ListTile(
                title: Text('Return: ${ret.id}'),
                subtitle: Text(
                  'Amount: K${ret.grandReturnAmount.toStringAsFixed(2)}',
                ),
                trailing: Text('${ret.date.toLocal()}'.split(' ')[0]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
