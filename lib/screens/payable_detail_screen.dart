import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/payable.dart';
import '../providers/payables_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/payment_dialog.dart';

class PayableDetailScreen extends StatelessWidget {
  final Payable payable;
  const PayableDetailScreen({super.key, required this.payable});

  void _recordPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PaymentDialog(
        onSave: (amount, method) {
          final payment = PayablePayment(amount: amount, date: DateTime.now(), method: method);
          Provider.of<PayablesProvider>(context, listen: false).addPaymentToPayable(payable.id, payment);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(payable.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit payable
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: ${payable.contact}'),
            Text('Amount: \$${payable.principal.toStringAsFixed(2)}'),
            Text('Due Date: ${DateFormat.yMd().format(payable.dueDate)}'),
            const SizedBox(height: 20),
            const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: payable.paymentHistory.length,
                itemBuilder: (ctx, i) {
                  final payment = payable.paymentHistory[i];
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