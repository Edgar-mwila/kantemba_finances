import 'package:flutter/material.dart';
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

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
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

        // Calculate comprehensive cash flow metrics
        final totalSales = sales.fold(
          0.0,
          (sum, sale) => sum + sale.grandTotal,
        );

        final totalReturns = returns.fold(
          0.0,
          (sum, ret) => sum + ret.grandReturnAmount,
        );

        // Operating Activities
        final cashInflows = totalSales;
        final returnsOutflow = totalReturns;

        // Categorize expenses for better analysis
        final operatingExpenses = expenses
            .where(
              (exp) =>
                  !exp.category.toLowerCase().contains('purchase') &&
                  !exp.category.toLowerCase().contains('inventory') &&
                  !exp.category.toLowerCase().contains('stock'),
            )
            .fold(0.0, (sum, exp) => sum + exp.amount);

        final inventoryExpenses = expenses
            .where(
              (exp) =>
                  exp.category.toLowerCase().contains('purchase') ||
                  exp.category.toLowerCase().contains('inventory') ||
                  exp.category.toLowerCase().contains('stock'),
            )
            .fold(0.0, (sum, exp) => sum + exp.amount);

        final damagedGoodsExpenses = expenses
            .where((exp) => exp.category.toLowerCase().contains('damaged'))
            .fold(0.0, (sum, exp) => sum + exp.amount);

        // Calculate net cash flows
        final netOperatingCashFlow =
            cashInflows - operatingExpenses - returnsOutflow;
        final netInvestingCashFlow =
            -inventoryExpenses; // Negative because it's an outflow
        final netCashFlow = netOperatingCashFlow + netInvestingCashFlow;

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
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash Flow',
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

            // Operating Activities Section
            _buildSection('OPERATING ACTIVITIES', [
              _buildSubsection('Cash Inflows', [
                _buildRow(
                  'Sales Revenue',
                  cashInflows,
                  Icons.point_of_sale,
                  Colors.green,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Cash Inflows',
                  cashInflows,
                  null,
                  Colors.green,
                  isBold: true,
                ),
              ]),
              _buildSubsection('Cash Outflows', [
                _buildRow(
                  'Operating Expenses',
                  operatingExpenses,
                  Icons.payments,
                  Colors.red,
                ),
                _buildRow(
                  'Returns & Refunds',
                  returnsOutflow,
                  Icons.assignment_return,
                  Colors.orange,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Cash Outflows',
                  operatingExpenses + returnsOutflow,
                  null,
                  Colors.red,
                  isBold: true,
                ),
              ]),
              _buildDivider(),
              _buildRow(
                'Net Operating Cash Flow',
                netOperatingCashFlow,
                null,
                netOperatingCashFlow >= 0 ? Colors.green : Colors.red,
                isBold: true,
              ),
            ], Colors.blue.shade50),
            const SizedBox(height: 16),

            // Investing Activities Section
            _buildSection('INVESTING ACTIVITIES', [
              _buildRow(
                'Inventory Purchases',
                inventoryExpenses,
                Icons.inventory,
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
                'Net Investing Cash Flow',
                netInvestingCashFlow,
                null,
                Colors.red,
                isBold: true,
              ),
            ], Colors.purple.shade50),
            const SizedBox(height: 16),

            // Net Cash Flow Section
            _buildSection(
              'NET CASH FLOW',
              [
                _buildRow(
                  'Net Cash Flow',
                  netCashFlow,
                  Icons.trending_up,
                  netCashFlow >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                  isTotal: true,
                ),
              ],
              netCashFlow >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            ),
            const SizedBox(height: 16),

            // Cash Flow Analysis
            _buildCashFlowAnalysisSection(
              netOperatingCashFlow,
              netInvestingCashFlow,
              netCashFlow,
              cashInflows,
              operatingExpenses + returnsOutflow,
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
                    reportType: 'cash_flow',
                    data: {
                      'cashInflows': cashInflows,
                      'operatingExpenses': operatingExpenses,
                      'returnsOutflow': returnsOutflow,
                      'inventoryExpenses': inventoryExpenses,
                      'damagedGoodsExpenses': damagedGoodsExpenses,
                      'netOperatingCashFlow': netOperatingCashFlow,
                      'netInvestingCashFlow': netInvestingCashFlow,
                      'netCashFlow': netCashFlow,
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
                                  'AI Cash Flow Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Cash Flow Trend: ${ai['trend'] ?? 'Analyzing...'}',
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

        if (isWindows) {
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
            title: const Text('Cash Flow'),
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

  Widget _buildCashFlowAnalysisSection(
    double netOperatingCashFlow,
    double netInvestingCashFlow,
    double netCashFlow,
    double cashInflows,
    double cashOutflows,
    double totalReturns,
    double totalSales,
  ) {
    final operatingCashFlowRatio =
        cashInflows > 0 ? (netOperatingCashFlow / cashInflows) * 100 : 0.0;
    final returnRate = totalSales > 0 ? (totalReturns / totalSales) * 100 : 0.0;
    final cashFlowEfficiency =
        cashInflows > 0
            ? ((cashInflows - cashOutflows) / cashInflows) * 100
            : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Cash Flow Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisCard(
                    'Operating Cash Flow',
                    '${operatingCashFlowRatio.toStringAsFixed(1)}%',
                    netOperatingCashFlow >= 0 ? Colors.green : Colors.red,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnalysisCard(
                    'Return Rate',
                    '${returnRate.toStringAsFixed(1)}%',
                    returnRate < 5 ? Colors.green : Colors.red,
                    Icons.assignment_return,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnalysisCard(
                    'Cash Flow Efficiency',
                    '${cashFlowEfficiency.toStringAsFixed(1)}%',
                    cashFlowEfficiency > 20 ? Colors.green : Colors.orange,
                    Icons.speed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisCard(
                    'Cash Flow Status',
                    netCashFlow >= 0 ? 'Positive' : 'Negative',
                    netCashFlow >= 0 ? Colors.green : Colors.red,
                    netCashFlow >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnalysisCard(
                    'Operating Efficiency',
                    netOperatingCashFlow >= 0 ? 'Good' : 'Poor',
                    netOperatingCashFlow >= 0 ? Colors.green : Colors.red,
                    Icons.assessment,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnalysisCard(
                    'Investment Level',
                    netInvestingCashFlow < -1000 ? 'High' : 'Low',
                    netInvestingCashFlow < -1000 ? Colors.orange : Colors.blue,
                    Icons.inventory,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
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
