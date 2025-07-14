import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class ExpensesProvider with ChangeNotifier {
  List<Expense> _expenses = [];

  List<Expense> get expenses => [..._expenses];

  // Get filtered expenses based on ShopProvider.currentShop
  List<Expense> get filteredExpenses {
    // This will be accessed from the UI with ShopProvider context
    return _expenses;
  }

  // Get all available shop IDs from expenses
  List<String> get availableShopIds {
    return _expenses.map((expense) => expense.shopId).toSet().toList();
  }

  // Get filtered expenses based on current shop (to be used with ShopProvider)
  List<Expense> getExpensesForShop(Shop? currentShop) {
    if (currentShop == null) {
      return _expenses; // Show all expenses when no shop is selected
    }
    return _expenses
        .where((expense) => expense.shopId == currentShop.id)
        .toList();
  }

  List<Expense> getExpensesForShopAndDateRange(
    Shop? currentShop,
    DateTime? start,
    DateTime? end,
  ) {
    return getExpensesForShop(currentShop).where((expense) {
      if (start != null && expense.date.isBefore(start)) return false;
      if (end != null && expense.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  Future<void> fetchAndSetExpenses(
    String businessId, {
    List<String>? shopIds,
  }) async {
    // Check if online and if business is premium
    bool isOnline = await ApiService.isOnline();
    final businessProvider = BusinessProvider();
    bool isPremium = businessProvider.isPremium;

    if (!isOnline || !isPremium) {
      // Offline mode or non-premium business: load from local database
      debugPrint(
        'ExpensesProvider: Loading expenses from local database (offline: ${!isOnline}, premium: $isPremium)',
      );
      try {
        final localExpenses = await DBHelper.getData('expenses');
        debugPrint(
          'ExpensesProvider: Loaded ${localExpenses} expenses from local DB',
        );
        _expenses =
            localExpenses
                .map(
                  (item) => Expense(
                    id: item['id'],
                    description: item['description'],
                    amount: (item['amount'] as num).toDouble(),
                    date: DateTime.parse(item['date']),
                    category: item['category'],
                    createdBy: item['createdBy'] ?? 'Default',
                    shopId: item['shopId'],
                  ),
                )
                .toList();
      } catch (e) {
        debugPrint('Error loading expenses from local DB: $e');
        _expenses = [];
      }
      notifyListeners();
      return;
    }

    // Online mode and premium business: fetch from API
    debugPrint('ExpensesProvider: Loading expenses from API');
    List<Expense> allExpenses = [];
    if (shopIds != null && shopIds.isNotEmpty) {
      for (final shopId in shopIds) {
        final query = 'expenses?businessId=$businessId&shopId=$shopId';
        final response = await ApiService.get(query);
        if (response.statusCode == 200) {
          dynamic data = json.decode(response.body);
          List<dynamic> dataList;
          if (data is List) {
            dataList = data;
          } else if (data is Map) {
            dataList = [data];
          } else if (data is String && data.trim().isNotEmpty) {
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
          allExpenses.addAll(
            dataList.map(
              (item) => Expense(
                id: item['id'],
                description: item['description'],
                amount: (item['amount'] as num).toDouble(),
                date: DateTime.parse(item['date']),
                category: item['category'],
                createdBy: item['createdBy'],
                shopId: item['shopId'],
              ),
            ),
          );
        }
      }
    } else {
      // No shopIds: fetch all for businessId
      final query = 'expenses?businessId=$businessId';
      final response = await ApiService.get(query);
      if (response.statusCode == 200) {
        dynamic data = json.decode(response.body);
        List<dynamic> dataList;
        if (data is List) {
          dataList = data;
        } else if (data is Map) {
          dataList = [data];
        } else if (data is String && data.trim().isNotEmpty) {
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
        allExpenses =
            dataList
                .map(
                  (item) => Expense(
                    id: item['id'],
                    description: item['description'],
                    amount: (item['amount'] as num).toDouble(),
                    date: DateTime.parse(item['date']),
                    category: item['category'],
                    createdBy: item['createdBy'],
                    shopId: item['shopId'],
                  ),
                )
                .toList();
      }
    }
    _expenses = allExpenses;
    notifyListeners();
  }

  Future<void> addExpense(
    Expense expense,
    String createdBy,
    String shopId,
  ) async {
    final businessProvider = BusinessProvider();
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('expenses', {
        'id': expense.id,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'shopId': shopId,
        'synced': 0,
      });
      _expenses.add(expense);
      notifyListeners();
      return;
    }
    // Online: use API
    await ApiService.post('expenses', {
      'id': expense.id,
      'description': expense.description,
      'amount': expense.amount,
      'category': expense.category,
      'date': expense.date.toIso8601String(),
      'createdBy': createdBy,
      'shopId': shopId,
    });
    _expenses.add(expense);
    notifyListeners();
  }

  Future<void> fetchAndSetExpensesHybrid(
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium) {
      final localExpenses = await DBHelper.getData('expenses');
      _expenses =
          localExpenses
              .map(
                (item) => Expense(
                  id: item['id'],
                  description: item['description'],
                  amount: (item['amount'] as num).toDouble(),
                  date: DateTime.parse(item['date']),
                  category: item['category'],
                  createdBy: item['createdBy'] ?? 'Default',
                  shopId: item['shopId'],
                ),
              )
              .toList();
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await fetchAndSetExpenses(businessProvider.id!);
      // Optionally, update local DB with latest online data
    } else {
      final localExpenses = await DBHelper.getData('expenses');
      _expenses =
          localExpenses
              .map(
                (item) => Expense(
                  id: item['id'],
                  description: item['description'],
                  amount: (item['amount'] as num).toDouble(),
                  date: DateTime.parse(item['date']),
                  category: item['category'],
                  createdBy: item['createdBy'],
                  shopId: item['shopId'],
                ),
              )
              .toList();
      notifyListeners();
    }
  }

  Future<void> addExpenseHybrid(
    Expense expense,
    String createdBy,
    String shopId,
    BusinessProvider businessProvider,
  ) async {
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('expenses', {
        'id': expense.id,
        'description': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'createdBy': createdBy,
        'shopId': shopId,
        'synced': 0,
      });
      _expenses.add(
        Expense(
          id: expense.id,
          description: expense.description,
          amount: expense.amount,
          date: expense.date,
          category: expense.category,
          createdBy: createdBy,
          shopId: shopId,
        ),
      );
      notifyListeners();
      return;
    }
    await addExpense(expense, createdBy, shopId);
  }

  Future<void> syncExpensesToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('expenses');
    for (final expense in unsynced) {
      await ApiService.post('expenses', {
        'id': expense['id'],
        'description': expense['description'],
        'amount': (expense['amount'] as num).toDouble(),
        'date': expense['date'],
        'category': expense['category'],
        'createdBy': expense['createdBy'],
        'shopId': expense['shopId'],
      });
      await DBHelper.markAsSynced('expenses', expense['id']);
    }
  }
}
