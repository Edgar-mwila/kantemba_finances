import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/widgets/new_expense_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import '../models/expense.dart';
import '../helpers/analytics_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'description'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('screen_open', data: {'screen': 'Expenses'});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _filterAndSortExpenses(List<Expense> expenses) {
    // Filter expenses based on search query
    List<Expense> filteredExpenses =
        expenses.where((expense) {
          if (_searchQuery.isEmpty) return true;

          final query = _searchQuery.toLowerCase();

          // Search by description
          if (expense.description.toLowerCase().contains(query)) return true;

          // Search by amount (convert to string for search)
          if (expense.amount.toString().contains(query)) return true;

          return false;
        }).toList();

    // Sort expenses
    filteredExpenses.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'description':
          comparison = a.description.compareTo(b.description);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filteredExpenses;
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Expanded search bar
          Expanded(
            child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by description or amount...',
              prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
              ),
              const SizedBox(width: 8),
          // Sort by dropdown
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'amount', child: Text('Amount')),
              DropdownMenuItem(value: 'description', child: Text('Description')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                  }
                },
            underline: Container(),
            style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortAscending ? 'Ascending' : 'Descending',
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesData = Provider.of<ExpensesProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered expenses based on current shop
        final expenses = expensesData.getExpensesForShop(
          shopProvider.currentShop,
        );

        final filteredAndSortedExpenses = _filterAndSortExpenses(expenses);

        if (isWindows(context)) {
          // Desktop layout: Centered, max width, header add button, table-like list
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Search and sort bar
                      _buildSearchAndSortBar(),
                      const SizedBox(height: 16),
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Description',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Shop',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child:
                            filteredAndSortedExpenses.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No expenses found.'
                                            : 'No expenses match your search.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your search terms.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filteredAndSortedExpenses.length,
                                  itemBuilder: (ctx, i) {
                                    final expense =
                                        filteredAndSortedExpenses[i];
                                    final shop = shopProvider.shops.firstWhere(
                                      (s) => s.id == expense.shopId,
                                      orElse: () => shopProvider.shops.first,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(expense.description),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              DateFormat(
                                                'yyyy-MM-dd - kk:mm',
                                              ).format(expense.date),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              shop.name,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'K${expense.amount.toStringAsFixed(2)}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton:
                (user != null &&
                        (user.permissions.contains('add_expense') ||
                            user.permissions.contains('all') ||
                            user.role == 'admin' ||
                            user.role == 'owner'))
                    ? FloatingActionButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (ctx) => Dialog(
                                child: SizedBox(
                                  width: 600,
                                  child: NewExpenseModal(),
                                ),
                              ),
                        );
                      },
                      backgroundColor: Colors.green.shade700,
                      child: const Icon(Icons.add),
                    )
                    : null,
          );
        }

        // Mobile layout
        return Scaffold(
          body: Column(
            children: [
              // Search and sort bar for mobile
              _buildSearchAndSortBar(),
              Expanded(
                child:
                    filteredAndSortedExpenses.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No expenses found.'
                                    : 'No expenses match your search.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search terms.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredAndSortedExpenses.length,
                          itemBuilder: (ctx, i) {
                            final expense = filteredAndSortedExpenses[i];
                            final shop = shopProvider.shops.firstWhere(
                              (s) => s.id == expense.shopId,
                              orElse: () => shopProvider.shops.first,
                            );

                            return ListTile(
                              title: Text(expense.description),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'yyyy-MM-dd - kk:mm',
                                    ).format(expense.date),
                                  ),
                                  Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                'K${expense.amount.toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
              ),
              // Bottom spacing for floating buttons
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton:
              (user != null &&
                      (user.permissions.contains('add_expense') ||
                          user.permissions.contains('all') ||
                          user.role == 'admin' ||
                          user.role == 'owner'))
                  ? FloatingActionButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => const NewExpenseModal(),
                      );
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Colors.green.shade700,
                  )
                  : null,
        );
      },
    );
  }
}
