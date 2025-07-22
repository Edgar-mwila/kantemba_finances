import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/loan.dart';
import '../providers/loans_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/payment_dialog.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  void _recordPayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PaymentDialog(
        onSave: (amount, method) {
          final payment = LoanPayment(amount: amount, date: DateTime.now(), method: method);
          Provider.of<LoansProvider>(context, listen: false).addPaymentToLoan(loan.id, payment);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loan.lenderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit loan
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: ${loan.lenderContact}'),
            Text('Amount: \$${loan.principal.toStringAsFixed(2)}'),
            Text('Due Date: ${DateFormat.yMd().format(loan.dueDate)}'),
            const SizedBox(height: 20),
            const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: loan.paymentHistory.length,
                itemBuilder: (ctx, i) {
                  final payment = loan.paymentHistory[i];
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