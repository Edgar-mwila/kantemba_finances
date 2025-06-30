import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class ExpensesProvider with ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => [..._expenses];

  Future<void> fetchAndSetExpenses() async {
    final dataList = await DBHelper.getData('expenses');
    _expenses = dataList
        .map(
          (item) => Expense(
            id: item['id'],
            description: item['description'],
            amount: item['amount'],
            date: DateTime.parse(item['date']),
            category: item['category'],
            createdBy: item['createdBy'],
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense, String createdBy) async {
    final newExpense = Expense(
      id: DateTime.now().toString(),
      description: expense.description,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      createdBy: createdBy,
    );
    _expenses.add(newExpense);
    notifyListeners();

    DBHelper.insert('expenses', {
      'id': newExpense.id,
      'description': newExpense.description,
      'amount': newExpense.amount,
      'date': newExpense.date.toIso8601String(),
      'category': newExpense.category,
      'createdBy': createdBy,
    });
  }
} 