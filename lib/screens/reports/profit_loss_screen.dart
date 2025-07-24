import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';
import '../../providers/receivables_provider.dart';
import '../../providers/payables_provider.dart';
import '../../providers/loans_provider.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
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
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);
    final returnsData = Provider.of<ReturnsProvider>(context);
    final receivablesProvider = Provider.of<ReceivablesProvider>(context);
    final payablesProvider = Provider.of<PayablesProvider>(context);
    final loansProvider = Provider.of<LoansProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered data based on current shop
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

        // Calculate comprehensive P&L metrics
        final totalSales = sales.fold(
          0.0,
          (sum, sale) => sum + sale.grandTotal,
        );

        // Calculate returns impact
        final totalReturns = returns.fold(
          0.0,
          (sum, ret) => sum + ret.grandReturnAmount,
        );

        // Calculate net sales (sales minus returns)
        final netSales = totalSales - totalReturns;

        // Calculate COGS (Cost of Goods Sold)
        final cogs = expenses
            .where(
              (exp) =>
                  exp.category.toLowerCase().contains('purchase') ||
                  exp.category.toLowerCase().contains('inventory') ||
                  exp.category.toLowerCase().contains('stock'),
            )
            .fold(0.0, (sum, exp) => sum + exp.amount);

        // Calculate gross profit
        final grossProfit = netSales - cogs;

        // Categorize expenses
        final operatingExpenses = expenses
            .where(
              (exp) =>
                  !exp.category.toLowerCase().contains('purchase') &&
                  !exp.category.toLowerCase().contains('inventory') &&
                  !exp.category.toLowerCase().contains('stock') &&
                  !exp.category.toLowerCase().contains('damaged'),
            )
            .fold(0.0, (sum, exp) => sum + exp.amount);

        final damagedGoodsExpenses = expenses
            .where((exp) => exp.category.toLowerCase().contains('damaged'))
            .fold(0.0, (sum, exp) => sum + exp.amount);

        final totalExpenses = operatingExpenses + damagedGoodsExpenses;

        // Calculate net profit
        final netProfit = grossProfit - totalExpenses;

        // Calculate profit margins
        final grossProfitMargin =
            netSales > 0 ? (grossProfit / netSales) * 100 : 0.0;
        final netProfitMargin =
            netSales > 0 ? (netProfit / netSales) * 100 : 0.0;

        // Use interestReceived and totalInterestPaid in the breakdown
        final interestReceived = receivablesProvider.receivables
            .expand((r) => r.paymentHistory)
            .where((p) => p.method.toLowerCase().contains('interest'))
            .fold<double>(0.0, (sum, p) => sum + p.amount);
        // Interest paid on payables and loans
        final interestPaidPayables = payablesProvider.payables
            .expand((p) => p.paymentHistory)
            .where((p) => p.method.toLowerCase().contains('interest'))
            .fold<double>(0.0, (sum, p) => sum + p.amount);
        final interestPaidLoans = loansProvider.loans
            .expand((l) => l.paymentHistory)
            .where((p) => p.method.toLowerCase().contains('interest'))
            .fold<double>(0.0, (sum, p) => sum + p.amount);
        final totalInterestPaid = interestPaidPayables + interestPaidLoans;

        // Now define reportContent here, using the calculated variables
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
                        const Icon(Icons.trending_up, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Profit & Loss',
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
                      'For the period ending ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Revenue Section
            _buildSection('REVENUE', [
              _buildRow(
                'Total Sales',
                totalSales,
                Icons.point_of_sale,
                Colors.blue,
              ),
              _buildRow(
                'Returns & Refunds',
                totalReturns,
                Icons.assignment_return,
                Colors.orange,
              ),
              _buildDivider(),
              _buildRow('Net Sales', netSales, null, Colors.blue, isBold: true),
            ], Colors.green.shade50),
            const SizedBox(height: 16),

            // Cost of Goods Sold Section
            _buildSection('COST OF GOODS SOLD', [
              _buildRow(
                'Inventory Purchases',
                cogs,
                Icons.inventory,
                Colors.red,
              ),
              _buildDivider(),
              _buildRow('Total COGS', cogs, null, Colors.red, isBold: true),
            ], Colors.red.shade50),
            const SizedBox(height: 16),

            // Gross Profit Section
            _buildSection('GROSS PROFIT', [
              _buildRow(
                'Gross Profit',
                grossProfit,
                Icons.account_balance_wallet,
                Colors.green,
                isBold: true,
              ),
              _buildRow(
                'Gross Profit Margin',
                grossProfitMargin,
                Icons.percent,
                Colors.green,
                isPercentage: true,
              ),
            ], Colors.green.shade100),
            const SizedBox(height: 16),

            // Operating Expenses Section
            _buildSection('OPERATING EXPENSES', [
              _buildRow(
                'Operating Expenses',
                operatingExpenses,
                Icons.payments,
                Colors.red,
              ),
              _buildRow(
                'Damaged Goods Write-offs',
                damagedGoodsExpenses,
                Icons.broken_image,
                Colors.orange,
              ),
              _buildDivider(),
              _buildRow(
                'Total Operating Expenses',
                totalExpenses,
                null,
                Colors.red,
                isBold: true,
              ),
            ], Colors.red.shade50),
            const SizedBox(height: 16),

            // Net Profit Section
            _buildSection(
              'NET PROFIT',
              [
                _buildRow(
                  'Net Profit',
                  netProfit,
                  Icons.trending_up,
                  netProfit >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                  isTotal: true,
                ),
                _buildRow(
                  'Net Profit Margin',
                  netProfitMargin,
                  Icons.percent,
                  netProfit >= 0 ? Colors.green : Colors.red,
                  isPercentage: true,
                ),
              ],
              netProfit >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            ),
            const SizedBox(height: 16),

            // Performance Metrics
            _buildPerformanceMetricsSection(
              netSales,
              grossProfit,
              netProfit,
              grossProfitMargin,
              netProfitMargin,
              totalReturns,
              totalSales,
            ),
            const SizedBox(height: 32),

            // Premium AI Analysis
            Consumer<BusinessProvider>(
              builder: (context, businessProvider, _) {
                if (!businessProvider.isPremium) return const SizedBox.shrink();
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchAIAnalysis(
                    businessId: businessProvider.id!,
                    reportType: 'profit_loss',
                    data: {
                      'totalSales': totalSales,
                      'netSales': netSales,
                      'totalReturns': totalReturns,
                      'grossProfit': grossProfit,
                      'grossProfitMargin': grossProfitMargin,
                      'netProfit': netProfit,
                      'netProfitMargin': netProfitMargin,
                      'operatingExpenses': operatingExpenses,
                      'damagedGoodsExpenses': damagedGoodsExpenses,
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
                                  'AI Profitability Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Profitability Trend: ${ai['trend'] ?? 'Analyzing...'}',
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
            title: const Text('Profit & Loss'),
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

  Widget _buildRow(
    String label,
    double amount,
    IconData? icon,
    Color? color, {
    bool isBold = false,
    bool isTotal = false,
    bool isPercentage = false,
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
            isPercentage
                ? '${amount.toStringAsFixed(1)}%'
                : 'K${amount.toStringAsFixed(2)}',
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

  Widget _buildPerformanceMetricsSection(
    double netSales,
    double grossProfit,
    double netProfit,
    double grossProfitMargin,
    double netProfitMargin,
    double totalReturns,
    double totalSales,
  ) {
    final returnRate = totalSales > 0 ? (totalReturns / totalSales) * 100 : 0.0;
    final expenseRatio =
        netSales > 0 ? ((grossProfit - netProfit) / netSales) * 100 : 0.0;

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
                  'Performance Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Gross Profit Margin',
                    '${grossProfitMargin.toStringAsFixed(1)}%',
                    grossProfitMargin > 20 ? Colors.green : Colors.orange,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    'Net Profit Margin',
                    '${netProfitMargin.toStringAsFixed(1)}%',
                    netProfitMargin > 10 ? Colors.green : Colors.orange,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    'Return Rate',
                    '${returnRate.toStringAsFixed(1)}%',
                    returnRate < 5 ? Colors.green : Colors.red,
                    Icons.assignment_return,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Expense Ratio',
                    '${expenseRatio.toStringAsFixed(1)}%',
                    expenseRatio < 80 ? Colors.green : Colors.red,
                    Icons.payments,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    'Profitability',
                    netProfit >= 0 ? '✔' : '⛔',
                    netProfit >= 0 ? Colors.green : Colors.red,
                    netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    'Efficiency',
                    grossProfitMargin > 20 ? 'High' : 'Low',
                    grossProfitMargin > 20 ? Colors.green : Colors.orange,
                    Icons.speed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
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
              label,
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

  Future<Map<String, dynamic>> fetchAIAnalysis({
    required String businessId,
    required String reportType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('http://192.168.43.129:4000/api/ai/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
