import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import '../../providers/shop_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final salesData = Provider.of<SalesProvider>(context);
    final expensesData = Provider.of<ExpensesProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered data based on current shop
        final inventory = inventoryData.getItemsForShop(
          shopProvider.currentShop,
        );
        final sales = salesData.getSalesForShop(shopProvider.currentShop);
        final expenses = expensesData.getExpensesForShop(
          shopProvider.currentShop,
        );

        final stockValue = inventory.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        final cash =
            sales.fold(0.0, (sum, sale) => sum + sale.grandTotal) -
            expenses.fold(0.0, (sum, exp) => sum + exp.amount);
        final assets = stockValue + cash;
        final liabilities = 0.0; // Not tracked yet
        final equity = assets - liabilities;

        return Scaffold(
          appBar: AppBar(title: const Text('Balance Sheet')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show current filter status
                // if (shopProvider.currentShop != null)
                //   Container(
                //     padding: const EdgeInsets.all(8),
                //     color: Colors.blue.shade50,
                //     child: Row(
                //       children: [
                //         const Icon(Icons.filter_list, size: 16),
                //         const SizedBox(width: 8),
                //         Text(
                //           'Filtered by: ${shopProvider.currentShop!.name}',
                //           style: const TextStyle(fontSize: 12),
                //         ),
                //         const Spacer(),
                //         TextButton(
                //           onPressed: () => shopProvider.setCurrentShop(null),
                //           child: const Text(
                //             'Clear',
                //             style: TextStyle(fontSize: 12),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Date: '),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Select (future)'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRow('Assets', assets, isBold: true),
                _buildRow('  - Stock Value', stockValue),
                _buildRow('  - Cash', cash),
                _buildRow('Liabilities', liabilities, isBold: true),
                const Divider(),
                _buildRow('Equity', equity, isBold: true),
                const SizedBox(height: 32),
                // Premium AI Analysis
                Consumer<BusinessProvider>(
                  builder: (context, businessProvider, _) {
                    if (!businessProvider.isPremium)
                      return const SizedBox.shrink();
                    return FutureBuilder<Map<String, dynamic>>(
                      future: fetchAIAnalysis(
                        businessId: businessProvider.id!,
                        reportType: 'balance_sheet',
                        data: {
                          'assets': assets,
                          'liabilities': liabilities,
                          'equity': equity,
                        },
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'AI analysis unavailable: \\${snapshot.error}',
                          );
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
                                      'AI Analysis',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Trend: \\${ai['trend']}'),
                                Text(
                                  'Recommendation: \\${ai['recommendation']}',
                                ),
                                ...?ai['insights']
                                    ?.map<Widget>((i) => Text(i))
                                    .toList(),
                                if (ai['forecast'] != null)
                                  Text(
                                    'Forecast: \\${jsonEncode(ai['forecast'])}',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            'K${value.toStringAsFixed(2)}',
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchAIAnalysis({
    required String businessId,
    required String reportType,
    Map<String, dynamic>? filters,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/ai/analysis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'businessId': businessId,
        'reportType': reportType,
        'filters': filters ?? {},
        'data': data,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch AI analysis');
    }
  }
}
