import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/screens/reports/profit_loss_screen.dart';
import 'package:kantemba_finances/screens/reports/cash_flow_screen.dart';
import 'package:kantemba_finances/screens/reports/balance_sheet_screen.dart';
import 'package:kantemba_finances/screens/reports/tax_summary_screen.dart';
import 'package:kantemba_finances/screens/reports/financial_snapshot_screen.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import '../screens/premium_screen.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final inventoryData = Provider.of<InventoryProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final currentUser = userProvider.currentUser;
    final isPremium = Provider.of<BusinessProvider>(context).isPremium;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered data based on current shop
        final sales = salesData.getSalesForShop(shopProvider.currentShop);
        final expenses = expensesData.getExpensesForShop(
          shopProvider.currentShop,
        );
        final inventory = inventoryData.getItemsForShop(
          shopProvider.currentShop,
        );

        final totalSales = sales.fold(
          0.0,
          (sum, item) => sum + item.grandTotal,
        );
        final totalDiscounts = sales.fold(
          0.0,
          (sum, item) => sum + (item.discount),
        );
        final totalExpenses = expenses.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
        final profit = totalSales - totalExpenses;
        final totalStockValue = inventory.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        if (isWindows(context)) {
          // Desktop layout: Centered, max width, grid for summary cards
          return Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Financial Reports',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isPremium)
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text(
                                            'AI Accounting Assistant',
                                          ),
                                          content: const Text(
                                            'Your detailed AI-powered accounting report will appear here. (Feature coming soon!)',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(ctx).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                icon: const Icon(Icons.smart_toy),
                                label: const Text('Get AI Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PremiumScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.star),
                                label: const Text('Upgrade for AI'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick Financial Snapshot
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.dashboard,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Financial Snapshot',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const FinancialSnapshotScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Icon(Icons.open_in_new),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Responsive grid for summary cards
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount;
                                    double width = constraints.maxWidth;
                                    if (width < 500) {
                                      crossAxisCount = 1;
                                    } else if (width < 700) {
                                      crossAxisCount = 2;
                                    } else {
                                      crossAxisCount = 3;
                                    }
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 2.5,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildSummaryCard(
                                          'Total Sales',
                                          'K${totalSales.toStringAsFixed(2)}',
                                          Colors.green,
                                          Icons.point_of_sale,
                                        ),
                                        _buildSummaryCard(
                                          'Total Expenses',
                                          'K${totalExpenses.toStringAsFixed(2)}',
                                          Colors.red,
                                          Icons.payments,
                                        ),
                                        _buildSummaryCard(
                                          'Net Profit',
                                          'K${profit.toStringAsFixed(2)}',
                                          profit >= 0
                                              ? Colors.blue
                                              : Colors.orange,
                                          Icons.trending_up,
                                        ),
                                        _buildSummaryCard(
                                          'Stock Value',
                                          'K${totalStockValue.toStringAsFixed(2)}',
                                          Colors.purple,
                                          Icons.inventory,
                                        ),
                                        _buildSummaryCard(
                                          'Total Discounts',
                                          'K${totalDiscounts.toStringAsFixed(2)}',
                                          Colors.orange,
                                          Icons.discount,
                                        ),
                                        _buildSummaryCard(
                                          'Profit Margin',
                                          '${totalSales > 0 ? ((profit / totalSales) * 100).toStringAsFixed(1) : 0.0}%',
                                          profit >= 0
                                              ? Colors.green
                                              : Colors.red,
                                          Icons.percent,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'Detailed Reports',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Report navigation as a grid
                        if (currentUser != null &&
                            (currentUser.hasPermission(
                                  UserPermissions.viewReports,
                                ) ||
                                currentUser.hasPermission(UserPermissions.all)))
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount;
                              double width = constraints.maxWidth;
                              if (width < 500) {
                                crossAxisCount = 1;
                              } else {
                                crossAxisCount = 2;
                              }
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 3.5,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildReportCard(
                                    context,
                                    Icons.trending_up,
                                    'Profit & Loss',
                                    'View detailed profit and loss statement',
                                    Colors.green,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const ProfitLossScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildReportCard(
                                    context,
                                    Icons.account_balance_wallet,
                                    'Cash Flow',
                                    'Track cash inflows and outflows',
                                    Colors.blue,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CashFlowScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildReportCard(
                                    context,
                                    Icons.account_balance,
                                    'Balance Sheet',
                                    'View assets, liabilities, and equity',
                                    Colors.purple,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const BalanceSheetScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildReportCard(
                                    context,
                                    Icons.receipt_long,
                                    'Tax Summary',
                                    'Review tax obligations and compliance',
                                    Colors.orange,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const TaxSummaryScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Mobile layout
          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Financial Snapshot
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dashboard, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Financial Snapshot',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const FinancialSnapshotScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Icon(Icons.open_in_new),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Summary cards in a row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMobileSummaryCard(
                                  'Sales',
                                  'K${totalSales.toStringAsFixed(2)}',
                                  Colors.green,
                                ),
                                const SizedBox(width: 12),
                                _buildMobileSummaryCard(
                                  'Expenses',
                                  'K${totalExpenses.toStringAsFixed(2)}',
                                  Colors.red,
                                ),
                                const SizedBox(width: 12),
                                _buildMobileSummaryCard(
                                  'Profit',
                                  'K${profit.toStringAsFixed(2)}',
                                  profit >= 0 ? Colors.blue : Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                _buildMobileSummaryCard(
                                  'Stock',
                                  'K${totalStockValue.toStringAsFixed(2)}',
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Detailed Reports',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report navigation as a list
                  if (currentUser != null &&
                      (currentUser.hasPermission(UserPermissions.viewReports) ||
                          currentUser.hasPermission(UserPermissions.all)))
                    Column(
                      children: [
                        _buildReportMenuItem(
                          context,
                          Icons.trending_up,
                          'Profit & Loss Statement',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfitLossScreen(),
                            ),
                          ),
                        ),
                        _buildReportMenuItem(
                          context,
                          Icons.swap_vert,
                          'Cash Flow Statement',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CashFlowScreen(),
                            ),
                          ),
                        ),
                        _buildReportMenuItem(
                          context,
                          Icons.account_balance,
                          'Balance Sheet',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BalanceSheetScreen(),
                            ),
                          ),
                        ),
                        _buildReportMenuItem(
                          context,
                          Icons.receipt_long,
                          'Tax Summary',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TaxSummaryScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 1,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
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
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
