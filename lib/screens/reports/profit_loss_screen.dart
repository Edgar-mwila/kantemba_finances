import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class ProfitLossScreen extends StatelessWidget {
  const ProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final totalSales = salesData.sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    final cogs = expensesData.expenses
        .where((exp) => exp.category.toLowerCase() == 'purchases')
        .fold(0.0, (sum, exp) => sum + exp.amount);
    final grossProfit = totalSales - cogs;
    final totalExpenses = expensesData.expenses
        .where((exp) => exp.category.toLowerCase() != 'purchases')
        .fold(0.0, (sum, exp) => sum + exp.amount);
    final netProfit = grossProfit - totalExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss Statement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Date Range: '),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Select (future)'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRow('Total Sales', totalSales),
            _buildRow('Cost of Goods Sold (COGS)', cogs),
            _buildRow('Gross Profit', grossProfit, isBold: true),
            _buildRow('Total Expenses', totalExpenses),
            const Divider(),
            _buildRow('Net Profit', netProfit, isBold: true),
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