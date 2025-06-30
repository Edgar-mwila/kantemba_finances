import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';

class TaxReportsScreen extends StatelessWidget {
  const TaxReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final totalVat = salesData.sales.fold(0.0, (sum, item) => sum + item.vat);
    final totalTurnoverTax =
        salesData.sales.fold(0.0, (sum, item) => sum + item.turnoverTax);
    final totalLevy = salesData.sales.fold(0.0, (sum, item) => sum + item.levy);
    final totalTaxPayable = totalVat + totalTurnoverTax + totalLevy;

    return Scaffold(
      appBar: AppBar(title: const Text('Tax Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTaxCard('Total VAT Payable',
                'K${totalVat.toStringAsFixed(2)}', Colors.deepOrange),
            _buildTaxCard('Total Turnover Tax Payable',
                'K${totalTurnoverTax.toStringAsFixed(2)}', Colors.teal),
            _buildTaxCard('Total Mobile Money Levy',
                'K${totalLevy.toStringAsFixed(2)}', Colors.indigo),
            const Divider(height: 32, thickness: 1),
            _buildTaxCard('Total Tax Payable',
                'K${totalTaxPayable.toStringAsFixed(2)}', Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
} 