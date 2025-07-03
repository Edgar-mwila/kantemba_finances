import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/expense.dart';

class ExpensesProvider with ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => [..._expenses];

  Future<void> fetchAndSetExpenses(String businessId) async {
    final response = await ApiService.get('expenses?businessId=$businessId');
    if (response.statusCode != 200) {
      //Return some error
    }
    if (kDebugMode) {
      print('Expenses API response: ${response.body}');
    }
    dynamic data = json.decode(response.body);
    List<dynamic> dataList;

    if (data is List) {
      dataList = data;
    } else if (data is Map) {
      dataList = [data];
    } else if (data is String && data.trim().isNotEmpty) {
      // Try to decode again if it's a JSON string
      var decoded = json.decode(data);
      if (decoded is List) {
        dataList = decoded;
      } else if (decoded is Map) {
        dataList = [decoded];
      } else {
        dataList = [];
      }
    } else {
      dataList = [];
    }
    _expenses =
        dataList
            .map(
              (item) => Expense(
                id: item['id'],
                description: item['description'],
                amount: (item['amount'] as num).toDouble(),
                date: DateTime.parse(item['date']),
                category: item['category'],
                createdBy: item['createdBy'],
              ),
            )
            .toList();
    notifyListeners();
  }

  Future<void> addExpense(
    Expense expense,
    String businessId,
    String createdBy,
  ) async {
    final newExpense = Expense(
      id: '${businessId}_${DateTime.now().toString()}',
      description: expense.description,
      amount: (expense.amount as num).toDouble(),
      date: expense.date,
      category: expense.category,
      createdBy: createdBy,
    );
    _expenses.add(newExpense);
    notifyListeners();

    await ApiService.post('expenses', {
      'id': newExpense.id,
      'description': newExpense.description,
      'amount': (newExpense.amount as num).toDouble(),
      'date': newExpense.date.toIso8601String(),
      'category': newExpense.category,
      'businessId': businessId,
      'createdBy': newExpense.createdBy,
    });
  }
}
