import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final totalInflow = salesData.sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    final totalOutflow = expensesData.expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final netCashFlow = totalInflow - totalOutflow;

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Flow Statement')),
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
            _buildRow('Total Cash Inflow', totalInflow),
            _buildRow('Total Cash Outflow', totalOutflow),
            const Divider(),
            _buildRow('Net Cash Flow', netCashFlow, isBold: true),
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