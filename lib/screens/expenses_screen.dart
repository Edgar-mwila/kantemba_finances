import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expensesData = Provider.of<ExpensesProvider>(context);
    final expenses = expensesData.expenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses'), centerTitle: true),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder:
            (ctx, i) => ListTile(
              title: Text(expenses[i].description),
              subtitle: Text(expenses[i].date.toIso8601String()),
              trailing: Text('K${expenses[i].amount.toStringAsFixed(2)}'),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show a modal to add a new expense
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
