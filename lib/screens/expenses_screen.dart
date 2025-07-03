import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/widgets/new_expense_modal.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expensesData = Provider.of<ExpensesProvider>(context);
    final expenses = expensesData.expenses;

    return Scaffold(
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => const NewExpenseModal(),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
