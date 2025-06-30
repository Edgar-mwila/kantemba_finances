import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class ExpenseBookScreen extends StatelessWidget {
  const ExpenseBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpensesProvider>(context).expenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Book')),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: ListTile(
            title: Text(expenses[i].description),
            subtitle: Text(expenses[i].date.toIso8601String().split('T')[0]),
            trailing: Text('K${expenses[i].amount.toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }
} 