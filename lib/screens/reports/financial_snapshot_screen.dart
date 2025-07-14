import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';

class FinancialSnapshotScreen extends StatefulWidget {
  const FinancialSnapshotScreen({super.key});

  @override
  State<FinancialSnapshotScreen> createState() =>
      _FinancialSnapshotScreenState();
}

class _FinancialSnapshotScreenState extends State<FinancialSnapshotScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'This Quarter':
        final quarter = ((now.month - 1) / 3).floor();
        _startDate = DateTime(now.year, quarter * 3 + 1, 1);
        _endDate = DateTime(now.year, (quarter + 1) * 3 + 1, 0);
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case 'All Time':
        _startDate = null;
        _endDate = null;
        break;
    }
  }

  List<dynamic> _filterDataByDateRange(List<dynamic> data) {
    if (_startDate == null || _endDate == null) {
      return data;
    }
    return data.where((item) {
      DateTime itemDate;
      if (item is Map<String, dynamic>) {
        itemDate = DateTime.parse(item['date']);
      } else {
        itemDate = item.date;
      }
      return itemDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        final inventoryProvider = Provider.of<InventoryProvider>(context);
        final salesProvider = Provider.of<SalesProvider>(context);
        final expensesProvider = Provider.of<ExpensesProvider>(context);
        final returnsProvider = Provider.of<ReturnsProvider>(context);

        // Get filtered data
        final inventory = inventoryProvider.getItemsForShop(
          shopProvider.currentShop,
        );
        final allSales = salesProvider.getSalesForShop(
          shopProvider.currentShop,
        );
        final allExpenses = expensesProvider.getExpensesForShop(
          shopProvider.currentShop,
        );
        final allReturns = returnsProvider.getReturnsForShop(
          shopProvider.currentShop,
        );

        final sales = _filterDataByDateRange(allSales);
        final expenses = _filterDataByDateRange(allExpenses);
        final returns = _filterDataByDateRange(allReturns);

        // Calculate key metrics
        final totalSales = sales.fold(
          0.0,
          (sum, sale) => sum + sale.grandTotal,
        );
        final totalExpenses = expenses.fold(
          0.0,
          (sum, exp) => sum + exp.amount,
        );
        final totalReturns = returns.fold(
          0.0,
          (sum, ret) => sum + ret.grandReturnAmount,
        );
        final stockValue = inventory.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        // Calculate profit metrics
        final grossProfit = totalSales - totalReturns;
        final netProfit = grossProfit - totalExpenses;
        final profitMargin =
            totalSales > 0 ? (netProfit / totalSales) * 100 : 0.0;

        // Calculate cash flow
        final cashInflow = totalSales;
        final cashOutflow = totalExpenses;
        final netCashFlow = cashInflow - cashOutflow;

        // Calculate inventory metrics
        final totalItems = inventory.length;
        final lowStockItems =
            inventory
                .where((item) => item.quantity <= item.lowStockThreshold)
                .length;
        final outOfStockItems =
            inventory.where((item) => item.quantity == 0).length;

        // Calculate damaged goods value
        final damagedGoodsValue = inventory.fold(0.0, (sum, item) {
          return sum +
              item.damagedRecords.fold(0.0, (itemSum, record) {
                return itemSum + (record.units * item.price);
              });
        });

        // Top performing items
        final itemSales = <String, double>{};
        for (final sale in sales) {
          for (final item in sale.items) {
            final itemName = item.product.name;
            itemSales[itemName] =
                (itemSales[itemName] ?? 0.0) + item.totalAmount;
          }
        }
        final topItems =
            itemSales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        // Expense breakdown
        final expenseCategories = <String, double>{};
        for (final expense in expenses) {
          final category = expense.category;
          expenseCategories[category] =
              (expenseCategories[category] ?? 0.0) + expense.amount;
        }
        final topExpenses =
            expenseCategories.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        Widget content = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Time Period',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _selectedPeriod,
                            items:
                                [
                                      'This Week',
                                      'This Month',
                                      'Last Month',
                                      'This Quarter',
                                      'This Year',
                                      'All Time',
                                    ]
                                    .map(
                                      (period) => DropdownMenuItem(
                                        value: period,
                                        child: Text(period),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                                _setDefaultDateRange();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _startDate == null
                            ? 'All Time'
                            : '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key Performance Indicators
              _buildKPISection(
                totalSales,
                totalExpenses,
                netProfit,
                profitMargin,
                netCashFlow,
                stockValue,
              ),
              const SizedBox(height: 16),

              // Inventory Overview
              _buildInventorySection(
                totalItems,
                lowStockItems,
                outOfStockItems,
                damagedGoodsValue,
                topItems,
              ),
              const SizedBox(height: 16),

              // Expense Analysis
              _buildExpenseSection(topExpenses),
              const SizedBox(height: 16),

              // Returns Analysis
              _buildReturnsSection(returns, totalReturns),
            ],
          ),
        );

        if (isWindows) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: content,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial Snapshot'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildKPISection(
    double totalSales,
    double totalExpenses,
    double netProfit,
    double profitMargin,
    double netCashFlow,
    double stockValue,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Performance Indicators',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final kpiItems = [
                  _buildKPICard(
                    'Total Sales',
                    totalSales,
                    Icons.point_of_sale,
                    Colors.blue,
                  ),
                  _buildKPICard(
                    'Total Expenses',
                    totalExpenses,
                    Icons.payments,
                    Colors.red,
                  ),
                  _buildKPICard(
                    'Net Profit',
                    netProfit,
                    Icons.account_balance_wallet,
                    netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildKPICard(
                    'Profit Margin',
                    profitMargin,
                    Icons.percent,
                    profitMargin >= 0 ? Colors.green : Colors.red,
                    isPercentage: true,
                  ),
                  _buildKPICard(
                    'Net Cash Flow',
                    netCashFlow,
                    Icons.trending_up,
                    netCashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildKPICard(
                    'Stock Value',
                    stockValue,
                    Icons.inventory,
                    Colors.orange,
                  ),
                ];

                if (isWide) {
                  return GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: kpiItems,
                  );
                } else {
                  return Column(
                    children:
                        kpiItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: item,
                              ),
                            )
                            .toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isPercentage = false,
  }) {
    return Card(
      elevation: 2,
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
              isPercentage
                  ? '${value.toStringAsFixed(1)}%'
                  : 'K${value.toStringAsFixed(2)}',
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

  Widget _buildInventorySection(
    int totalItems,
    int lowStockItems,
    int outOfStockItems,
    double damagedGoodsValue,
    List<MapEntry<String, double>> topItems,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Inventory Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInventoryMetric(
                    'Total Items',
                    totalItems.toString(),
                    Icons.category,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInventoryMetric(
                    'Low Stock',
                    lowStockItems.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInventoryMetric(
                    'Out of Stock',
                    outOfStockItems.toString(),
                    Icons.remove_shopping_cart,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInventoryMetric(
                    'Damaged Goods Value',
                    'K${damagedGoodsValue.toStringAsFixed(2)}',
                    Icons.broken_image,
                    Colors.red,
                  ),
                ),
              ],
            ),
            if (topItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Top Performing Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...topItems
                  .take(5)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'K${item.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSection(List<MapEntry<String, double>> topExpenses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Expense Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topExpenses.isNotEmpty) ...[
              ...topExpenses
                  .take(5)
                  .map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              expense.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'K${expense.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ] else ...[
              const Text(
                'No expenses recorded in this period',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReturnsSection(List<dynamic> returns, double totalReturns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_return, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Returns Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInventoryMetric(
                    'Total Returns',
                    'K${totalReturns.toStringAsFixed(2)}',
                    Icons.assignment_return,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInventoryMetric(
                    'Return Count',
                    returns.length.toString(),
                    Icons.list,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            if (returns.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recent Returns',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...returns
                  .take(3)
                  .map(
                    (ret) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Return ${ret.id.substring(0, 8)}...',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'K${ret.grandReturnAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
