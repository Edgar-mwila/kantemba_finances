import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/widgets/new_expense_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../models/shop.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

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

        if (isWindows) {
          // Desktop layout: Centered, max width, header add button, table-like list
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          if (user != null &&
                              (user.permissions.contains('add_expense') ||
                                  user.permissions.contains('all') ||
                                  user.role == 'admin' ||
                                  user.role == 'owner'))
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: SizedBox(
                                      width: 400,
                                      child: NewExpenseModal(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Expense'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: expenses.isEmpty
                            ? const Center(child: Text('No expenses found.'))
                            : ListView.builder(
                                itemCount: expenses.length,
                                itemBuilder: (ctx, i) {
                                  final expense = expenses[i];
                                  final shop = shopProvider.shops.firstWhere(
                                    (s) => s.id == expense.shopId,
                                    orElse: () => Shop(
                                      id: expense.shopId,
                                      name: 'Unknown Shop',
                                      businessId: '',
                                    ),
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(expense.description)),
                                        Expanded(flex: 2, child: Text(expense.date.toIso8601String())),
                                        Expanded(flex: 2, child: Text(shop.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('K${expense.amount.toStringAsFixed(2)}')),
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
          );
        }

        // Mobile layout (unchanged)
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final expense = expenses[i];
                    final shop = shopProvider.shops.firstWhere(
                      (s) => s.id == expense.shopId,
                      orElse:
                          () => Shop(
                            id: expense.shopId,
                            name: 'Unknown Shop',
                            businessId: '',
                          ),
                    );

                    return ListTile(
                      title: Text(expense.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.date.toIso8601String()),
                          Text(
                            'Shop: ${shop.name}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text('K${expense.amount.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
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
