import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class TaxSummaryScreen extends StatelessWidget {
  const TaxSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final totalSales = salesData.sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    final totalExpenses = expensesData.expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final profit = totalSales - totalExpenses;
    final isVatRegistered = totalSales >= 800000.0;
    final isTurnoverTax = totalSales < 5000000.0;
    final corporateTax = profit > 0 ? profit * 0.30 : 0.0;
    final vat = isVatRegistered ? totalSales * 0.16 : 0.0;
    final turnoverTax = isTurnoverTax ? totalSales * 0.05 : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tax Summary')),
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
            _buildRow('Total Expenses', totalExpenses),
            _buildRow('Profit', profit),
            const Divider(),
            _buildRow('Corporate Tax (30%)', corporateTax),
            _buildRow('VAT (16%)', vat),
            _buildRow('Turnover Tax (5%)', turnoverTax),
            const Divider(),
            const Text('Other taxes (PAYE, SDL, NAPSA, Withholding, Property Transfer) not tracked.'),
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