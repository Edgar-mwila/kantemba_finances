import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final stockValue = inventoryData.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final cash = salesData.sales.fold(0.0, (sum, sale) => sum + sale.grandTotal) - expensesData.expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final assets = stockValue + cash;
    final liabilities = 0.0; // Not tracked yet
    final equity = assets - liabilities;

    return Scaffold(
      appBar: AppBar(title: const Text('Balance Sheet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Date: '),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Select (future)'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRow('Assets', assets, isBold: true),
            _buildRow('  - Stock Value', stockValue),
            _buildRow('  - Cash', cash),
            _buildRow('Liabilities', liabilities, isBold: true),
            const Divider(),
            _buildRow('Equity', equity, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text('K${value.toStringAsFixed(2)}', style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
} 