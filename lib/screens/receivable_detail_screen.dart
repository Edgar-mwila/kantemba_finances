import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receivable.dart';
import '../providers/receivables_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/payment_dialog.dart';

class ReceivableDetailScreen extends StatelessWidget {
  final Receivable receivable;
  const ReceivableDetailScreen({super.key, required this.receivable});

  void _recordPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PaymentDialog(
        onSave: (amount, method) {
          final payment = ReceivablePayment(amount: amount, date: DateTime.now(), method: method);
          Provider.of<ReceivablesProvider>(context, listen: false).addPaymentToReceivable(receivable.id, payment);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receivable.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit receivable
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: ${receivable.contact}'),
            Text('Amount: \$${receivable.principal.toStringAsFixed(2)}'),
            Text('Due Date: ${DateFormat.yMd().format(receivable.dueDate)}'),
            const SizedBox(height: 20),
            const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: receivable.paymentHistory.length,
                itemBuilder: (ctx, i) {
                  final payment = receivable.paymentHistory[i];
                  return ListTile(
                    title: Text('Amount: \$${payment.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Date: ${DateFormat.yMd().format(payment.date)}'),
                    trailing: Text(payment.method),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _recordPayment(context),
        child: const Icon(Icons.payment),
      ),
    );
  }
} 