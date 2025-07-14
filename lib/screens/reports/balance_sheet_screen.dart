import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import '../../providers/shop_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);

    // Ensure initial date range doesn't exceed current date
    DateTime? initialStart = _startDate;
    DateTime? initialEnd = _endDate;

    if (initialEnd != null && initialEnd.isAfter(lastDate)) {
      initialEnd = lastDate;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange:
          initialStart != null && initialEnd != null
              ? DateTimeRange(start: initialStart, end: initialEnd)
              : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
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
        // Handle different data types
        itemDate = item.date;
      }
      return itemDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final returnsData = Provider.of<ReturnsProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered data based on current shop
        final inventory = inventoryData.getItemsForShop(
          shopProvider.currentShop,
        );
        final allSales = salesData.getSalesForShop(shopProvider.currentShop);
        final allExpenses = expensesData.getExpensesForShop(
          shopProvider.currentShop,
        );
        final allReturns = returnsData.getReturnsForShop(
          shopProvider.currentShop,
        );

        // Filter data by date range
        final sales = _filterDataByDateRange(allSales);
        final expenses = _filterDataByDateRange(allExpenses);
        final returns = _filterDataByDateRange(allReturns);

        // Calculate comprehensive financial metrics
        final stockValue = inventory.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        // Calculate cash position
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
        final netCashFlow = totalSales - totalExpenses - totalReturns;

        // Calculate damaged goods value
        final damagedGoodsValue = inventory.fold(0.0, (sum, item) {
          return sum +
              item.damagedRecords.fold(0.0, (itemSum, record) {
                return itemSum + (record.units * item.price);
              });
        });

        // Calculate accounts receivable (outstanding sales)
        final accountsReceivable = sales.fold(0.0, (sum, sale) {
          // Assuming all sales are cash sales for now
          return sum;
        });

        // Calculate accounts payable (outstanding expenses)
        final accountsPayable = expenses.fold(0.0, (sum, exp) {
          // Assuming all expenses are paid immediately for now
          return sum;
        });

        // Assets
        final currentAssets = stockValue + netCashFlow + accountsReceivable;
        final fixedAssets = 0.0; // Not tracked yet
        final totalAssets = currentAssets + fixedAssets;

        // Liabilities
        final currentLiabilities = accountsPayable;
        final longTermLiabilities = 0.0; // Not tracked yet
        final totalLiabilities = currentLiabilities + longTermLiabilities;

        // Equity
        final equity = totalAssets - totalLiabilities;

        Widget reportContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Balance Sheet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _selectDateRange,
                          child: const Icon(Icons.calendar_today),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As of ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assets Section
            _buildSection('ASSETS', [
              _buildSubsection('Current Assets', [
                _buildRow(
                  'Inventory (Stock Value)',
                  stockValue,
                  Icons.inventory,
                  Colors.orange,
                ),
                _buildRow(
                  'Cash & Cash Equivalents',
                  netCashFlow,
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                _buildRow(
                  'Accounts Receivable',
                  accountsReceivable,
                  Icons.receipt,
                  Colors.blue,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Current Assets',
                  currentAssets,
                  null,
                  Colors.blue,
                  isBold: true,
                ),
              ]),
              _buildSubsection('Fixed Assets', [
                _buildRow(
                  'Equipment & Machinery',
                  fixedAssets,
                  Icons.build,
                  Colors.grey,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Fixed Assets',
                  fixedAssets,
                  null,
                  Colors.grey,
                  isBold: true,
                ),
              ]),
              _buildDivider(),
              _buildRow(
                'TOTAL ASSETS',
                totalAssets,
                null,
                Colors.blue,
                isBold: true,
                isTotal: true,
              ),
            ], Colors.blue.shade50),
            const SizedBox(height: 16),

            // Liabilities Section
            _buildSection('LIABILITIES', [
              _buildSubsection('Current Liabilities', [
                _buildRow(
                  'Accounts Payable',
                  currentLiabilities,
                  Icons.payment,
                  Colors.red,
                ),
                _buildRow(
                  'Short-term Loans',
                  0.0,
                  Icons.account_balance,
                  Colors.red,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Current Liabilities',
                  currentLiabilities,
                  null,
                  Colors.red,
                  isBold: true,
                ),
              ]),
              _buildSubsection('Long-term Liabilities', [
                _buildRow(
                  'Long-term Loans',
                  longTermLiabilities,
                  Icons.account_balance,
                  Colors.red.shade700,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Long-term Liabilities',
                  longTermLiabilities,
                  null,
                  Colors.red.shade700,
                  isBold: true,
                ),
              ]),
              _buildDivider(),
              _buildRow(
                'TOTAL LIABILITIES',
                totalLiabilities,
                null,
                Colors.red,
                isBold: true,
                isTotal: true,
              ),
            ], Colors.red.shade50),
            const SizedBox(height: 16),

            // Equity Section
            _buildSection('EQUITY', [
              _buildRow(
                'Owner\'s Equity',
                equity,
                Icons.person,
                Colors.green,
                isBold: true,
              ),
              _buildDivider(),
              _buildRow(
                'TOTAL EQUITY',
                equity,
                null,
                Colors.green,
                isBold: true,
                isTotal: true,
              ),
            ], Colors.green.shade50),
            const SizedBox(height: 16),

            // Financial Health Indicators
            _buildFinancialHealthSection(
              totalAssets,
              totalLiabilities,
              equity,
              stockValue,
              damagedGoodsValue,
            ),
            const SizedBox(height: 32),

            // Premium AI Analysis
            Consumer<BusinessProvider>(
              builder: (context, businessProvider, _) {
                if (!businessProvider.isPremium) return const SizedBox.shrink();
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchAIAnalysis(
                    businessId: businessProvider.id!,
                    reportType: 'balance_sheet',
                    data: {
                      'totalAssets': totalAssets,
                      'totalLiabilities': totalLiabilities,
                      'equity': equity,
                      'currentAssets': currentAssets,
                      'currentLiabilities': currentLiabilities,
                      'stockValue': stockValue,
                      'damagedGoodsValue': damagedGoodsValue,
                      'startDate': _startDate?.toIso8601String(),
                      'endDate': _endDate?.toIso8601String(),
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('AI analysis unavailable: ${snapshot.error}');
                    }
                    final ai = snapshot.data!;
                    return Card(
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.only(top: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.psychology,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI Financial Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Financial Health: ${ai['trend'] ?? 'Analyzing...'}',
                            ),
                            Text(
                              'Recommendation: ${ai['recommendation'] ?? 'No recommendations available'}',
                            ),
                            ...?ai['insights']
                                ?.map<Widget>((i) => Text('• $i'))
                                .toList(),
                            if (ai['forecast'] != null)
                              Text('Forecast: ${jsonEncode(ai['forecast'])}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );

        if (isWindows(context)) {
          reportContent = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: reportContent,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Balance Sheet'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: reportContent,
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> children,
    Color backgroundColor,
  ) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSubsection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRow(
    String label,
    double amount,
    IconData? icon,
    Color? color, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            'K${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 16);
  }

  Widget _buildFinancialHealthSection(
    double totalAssets,
    double totalLiabilities,
    double equity,
    double stockValue,
    double damagedGoodsValue,
  ) {
    final debtToEquityRatio = equity > 0 ? totalLiabilities / equity : 0.0;
    final currentRatio =
        totalAssets > 0
            ? totalAssets / (totalLiabilities > 0 ? totalLiabilities : 1)
            : 0.0;
    final damagedGoodsPercentage =
        stockValue > 0 ? (damagedGoodsValue / stockValue) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Financial Health Indicators',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator(
                    'Debt-to-Equity',
                    debtToEquityRatio,
                    '${debtToEquityRatio.toStringAsFixed(2)}:1',
                    debtToEquityRatio < 1 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildHealthIndicator(
                    'Current Ratio',
                    currentRatio,
                    currentRatio.toStringAsFixed(2),
                    currentRatio > 1.5 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildHealthIndicator(
                    'Damaged Goods %',
                    damagedGoodsPercentage,
                    '${damagedGoodsPercentage.toStringAsFixed(1)}%',
                    damagedGoodsPercentage < 5 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(
    String label,
    double value,
    String displayValue,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchAIAnalysis({
    required String businessId,
    required String reportType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/ai/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': businessId,
          'reportType': reportType,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'trend': 'Analysis unavailable',
          'recommendation': 'Unable to generate recommendations',
          'insights': ['Please check your connection and try again'],
        };
      }
    } catch (e) {
      return {
        'trend': 'Analysis unavailable',
        'recommendation': 'Unable to generate recommendations',
        'insights': ['Please check your connection and try again'],
      };
    }
  }
}
