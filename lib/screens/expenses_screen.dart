import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/widgets/new_expense_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../models/shop.dart';

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

        return Scaffold(
          body: Column(
            children: [
              // Show current filter status
              // if (shopProvider.currentShop != null)
              //   Container(
              //     padding: const EdgeInsets.all(8),
              //     color: Colors.blue.shade50,
              //     child: Row(
              //       children: [
              //         const Icon(Icons.filter_list, size: 16),
              //         const SizedBox(width: 8),
              //         Text(
              //           'Filtered by: ${shopProvider.currentShop!.name}',
              //           style: const TextStyle(fontSize: 12),
              //         ),
              //         const Spacer(),
              //         TextButton(
              //           onPressed: () => shopProvider.setCurrentShop(null),
              //           child: const Text(
              //             'Clear',
              //             style: TextStyle(fontSize: 12),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
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
