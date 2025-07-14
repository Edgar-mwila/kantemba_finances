import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';

class TaxSummaryScreen extends StatefulWidget {
  const TaxSummaryScreen({super.key});

  @override
  State<TaxSummaryScreen> createState() => _TaxSummaryScreenState();
}

class _TaxSummaryScreenState extends State<TaxSummaryScreen> {
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
    final returnsData = Provider.of<ReturnsProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered data based on current shop
        final allSales = salesData.getSalesForShop(shopProvider.currentShop);
        final allReturns = returnsData.getReturnsForShop(
          shopProvider.currentShop,
        );

        // Filter data by date range
        final sales = _filterDataByDateRange(allSales);
        final returns = _filterDataByDateRange(allReturns);

        // Calculate comprehensive tax metrics
        final totalSales = sales.fold(
          0.0,
          (sum, sale) => sum + sale.grandTotal,
        );

        final totalReturns = returns.fold(
          0.0,
          (sum, ret) => sum + ret.grandReturnAmount,
        );

        // Calculate net sales (sales minus returns)
        final netSales = totalSales - totalReturns;

        // Calculate taxes from sales
        final vat = sales.fold(0.0, (sum, sale) => sum + sale.vat);
        final turnoverTax = sales.fold(
          0.0,
          (sum, sale) => sum + sale.turnoverTax,
        );
        final levy = sales.fold(0.0, (sum, sale) => sum + sale.levy);

        // Calculate taxes from returns (refunds)
        final vatRefunds = returns.fold(0.0, (sum, ret) => sum + ret.vat);
        final turnoverTaxRefunds = returns.fold(
          0.0,
          (sum, ret) => sum + ret.turnoverTax,
        );
        final levyRefunds = returns.fold(0.0, (sum, ret) => sum + ret.levy);

        // Calculate net taxes (taxes minus refunds)
        final netVat = vat - vatRefunds;
        final netTurnoverTax = turnoverTax - turnoverTaxRefunds;
        final netLevy = levy - levyRefunds;
        final totalTax = netVat + netTurnoverTax + netLevy;

        // Calculate tax rates
        final vatRate = netSales > 0 ? (netVat / netSales) * 100 : 0.0;
        final turnoverTaxRate =
            netSales > 0 ? (netTurnoverTax / netSales) * 100 : 0.0;
        final levyRate = netSales > 0 ? (netLevy / netSales) * 100 : 0.0;
        final totalTaxRate = netSales > 0 ? (totalTax / netSales) * 100 : 0.0;

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
                        const Icon(Icons.receipt_long, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Tax Summary',
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

            // Sales Summary Section
            _buildSection('SALES SUMMARY', [
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
            ], Colors.blue.shade50),
            const SizedBox(height: 16),

            // Tax Collection Section
            _buildSection('TAX COLLECTION', [
              _buildSubsection('Taxes Collected', [
                _buildRow('VAT', vat, Icons.receipt, Colors.green),
                _buildRow(
                  'Turnover Tax',
                  turnoverTax,
                  Icons.account_balance,
                  Colors.green,
                ),
                _buildRow('Levy', levy, Icons.policy, Colors.green),
                _buildDivider(),
                _buildRow(
                  'Total Taxes Collected',
                  vat + turnoverTax + levy,
                  null,
                  Colors.green,
                  isBold: true,
                ),
              ]),
              _buildSubsection('Tax Refunds', [
                _buildRow(
                  'VAT Refunds',
                  vatRefunds,
                  Icons.assignment_return,
                  Colors.orange,
                ),
                _buildRow(
                  'Turnover Tax Refunds',
                  turnoverTaxRefunds,
                  Icons.assignment_return,
                  Colors.orange,
                ),
                _buildRow(
                  'Levy Refunds',
                  levyRefunds,
                  Icons.assignment_return,
                  Colors.orange,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Tax Refunds',
                  vatRefunds + turnoverTaxRefunds + levyRefunds,
                  null,
                  Colors.orange,
                  isBold: true,
                ),
              ]),
            ], Colors.green.shade50),
            const SizedBox(height: 16),

            // Net Tax Liability Section
            _buildSection(
              'NET TAX LIABILITY',
              [
                _buildRow(
                  'Net VAT',
                  netVat,
                  Icons.receipt,
                  netVat >= 0 ? Colors.green : Colors.red,
                ),
                _buildRow(
                  'Net Turnover Tax',
                  netTurnoverTax,
                  Icons.account_balance,
                  netTurnoverTax >= 0 ? Colors.green : Colors.red,
                ),
                _buildRow(
                  'Net Levy',
                  netLevy,
                  Icons.policy,
                  netLevy >= 0 ? Colors.green : Colors.red,
                ),
                _buildDivider(),
                _buildRow(
                  'Total Net Tax Liability',
                  totalTax,
                  null,
                  totalTax >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                  isTotal: true,
                ),
              ],
              totalTax >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            ),
            const SizedBox(height: 16),

            // Tax Rates Section
            _buildSection('TAX RATES', [
              _buildRow(
                'VAT Rate',
                vatRate,
                Icons.percent,
                Colors.blue,
                isPercentage: true,
              ),
              _buildRow(
                'Turnover Tax Rate',
                turnoverTaxRate,
                Icons.percent,
                Colors.blue,
                isPercentage: true,
              ),
              _buildRow(
                'Levy Rate',
                levyRate,
                Icons.percent,
                Colors.blue,
                isPercentage: true,
              ),
              _buildDivider(),
              _buildRow(
                'Total Tax Rate',
                totalTaxRate,
                Icons.percent,
                Colors.blue,
                isPercentage: true,
                isBold: true,
              ),
            ], Colors.blue.shade50),
            const SizedBox(height: 16),

            // Tax Compliance Analysis
            _buildTaxComplianceSection(
              totalTax,
              totalTaxRate,
              netSales,
              totalReturns,
              totalSales,
              vatRate,
              turnoverTaxRate,
              levyRate,
            ),
            const SizedBox(height: 32),

            // Premium AI Analysis
            Consumer<BusinessProvider>(
              builder: (context, businessProvider, _) {
                if (!businessProvider.isPremium) return const SizedBox.shrink();
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchAIAnalysis(
                    businessId: businessProvider.id!,
                    reportType: 'tax_summary',
                    data: {
                      'totalSales': totalSales,
                      'netSales': netSales,
                      'totalReturns': totalReturns,
                      'vat': vat,
                      'turnoverTax': turnoverTax,
                      'levy': levy,
                      'vatRefunds': vatRefunds,
                      'turnoverTaxRefunds': turnoverTaxRefunds,
                      'levyRefunds': levyRefunds,
                      'netVat': netVat,
                      'netTurnoverTax': netTurnoverTax,
                      'netLevy': netLevy,
                      'totalTax': totalTax,
                      'vatRate': vatRate,
                      'turnoverTaxRate': turnoverTaxRate,
                      'levyRate': levyRate,
                      'totalTaxRate': totalTaxRate,
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
                                  'AI Tax Compliance Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Compliance Status: ${ai['trend'] ?? 'Analyzing...'}',
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
            title: const Text('Tax Summary'),
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
                ? '${amount.toStringAsFixed(2)}%'
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

  Widget _buildTaxComplianceSection(
    double totalTax,
    double totalTaxRate,
    double netSales,
    double totalReturns,
    double totalSales,
    double vatRate,
    double turnoverTaxRate,
    double levyRate,
  ) {
    final returnRate = totalSales > 0 ? (totalReturns / totalSales) * 100 : 0.0;
    final taxEfficiency = netSales > 0 ? (totalTax / netSales) * 100 : 0.0;
    final complianceScore = _calculateComplianceScore(
      vatRate,
      turnoverTaxRate,
      levyRate,
      returnRate,
    );

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
                  'Tax Compliance Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComplianceCard(
                    'Tax Rate',
                    '${totalTaxRate.toStringAsFixed(2)}%',
                    totalTaxRate > 0 ? Colors.green : Colors.red,
                    Icons.percent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildComplianceCard(
                    'Return Rate',
                    '${returnRate.toStringAsFixed(1)}%',
                    returnRate < 5 ? Colors.green : Colors.red,
                    Icons.assignment_return,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildComplianceCard(
                    'Tax Efficiency',
                    '${taxEfficiency.toStringAsFixed(1)}%',
                    taxEfficiency > 0 ? Colors.green : Colors.orange,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComplianceCard(
                    'Compliance Score',
                    '${complianceScore.toStringAsFixed(0)}%',
                    complianceScore > 80
                        ? Colors.green
                        : complianceScore > 60
                        ? Colors.orange
                        : Colors.red,
                    Icons.assessment,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildComplianceCard(
                    'VAT Rate',
                    '${vatRate.toStringAsFixed(2)}%',
                    vatRate > 0 ? Colors.green : Colors.red,
                    Icons.receipt,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildComplianceCard(
                    'Turnover Tax',
                    '${turnoverTaxRate.toStringAsFixed(2)}%',
                    turnoverTaxRate > 0 ? Colors.green : Colors.red,
                    Icons.account_balance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateComplianceScore(
    double vatRate,
    double turnoverTaxRate,
    double levyRate,
    double returnRate,
  ) {
    double score = 100.0;

    // Deduct points for missing taxes
    if (vatRate <= 0) score -= 20;
    if (turnoverTaxRate <= 0) score -= 15;
    if (levyRate <= 0) score -= 10;

    // Deduct points for high return rates (potential tax evasion)
    if (returnRate > 10)
      score -= 20;
    else if (returnRate > 5)
      score -= 10;

    return score.clamp(0.0, 100.0);
  }

  Widget _buildComplianceCard(
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
