import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/screens/reports/profit_loss_screen.dart';
import 'package:kantemba_finances/screens/reports/cash_flow_screen.dart';
import 'package:kantemba_finances/screens/reports/balance_sheet_screen.dart';
import 'package:kantemba_finances/screens/reports/tax_summary_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final inventoryData = Provider.of<InventoryProvider>(context);

    final totalSales = salesData.sales.fold(
      0.0,
      (sum, item) => sum + item.grandTotal,
    );
    final totalExpenses = expensesData.expenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final profit = totalSales - totalExpenses;
    final totalStockValue = inventoryData.items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Snapshot',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Sales',
                    'K${totalSales.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Expenses',
                    'K${totalExpenses.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Profit / Loss',
                    'K${profit.toStringAsFixed(2)}',
                    profit >= 0 ? Colors.blue : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Stock Value',
                    'K${totalStockValue.toStringAsFixed(2)}',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Detailed Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _buildReportMenuItem(
              context,
              Icons.receipt_long,
              'Profit & Loss Statement',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfitLossScreen()),
              ),
            ),
            _buildReportMenuItem(
              context,
              Icons.swap_vert,
              'Cash Flow Statement',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashFlowScreen()),
              ),
            ),
            _buildReportMenuItem(
              context,
              Icons.account_balance,
              'Balance Sheet',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceSheetScreen()),
              ),
            ),
            _buildReportMenuItem(
              context,
              Icons.receipt,
              'Tax Summary',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaxSummaryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
