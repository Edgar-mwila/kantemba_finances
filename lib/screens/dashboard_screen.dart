import 'package:flutter/material.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/screens/settings_screen.dart';
import 'package:kantemba_finances/screens/shop_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/screens/premium_screen.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final expensesProvider = Provider.of<ExpensesProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final usersProvider = Provider.of<UsersProvider>(context);
    final isPremium = businessProvider.isPremium;

    // Data for overviews
    final currentUser = usersProvider.currentUser;
    final sales = salesProvider.getSalesForShop(shopProvider.currentShop);
    final expenses = expensesProvider.getExpensesForShop(
      shopProvider.currentShop,
    );
    final inventory = inventoryProvider.getItemsForShop(
      shopProvider.currentShop,
    );
    final totalSales = sales.fold(0.0, (sum, item) => sum + item.grandTotal);
    final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final profit = totalSales - totalExpenses;
    final totalStockValue = inventory.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final lowStockItems =
        inventory
            .where((item) => item.quantity <= item.lowStockThreshold)
            .toList();
    final recentSales = sales.reversed.take(5).toList().reversed.toList();
    final recentExpenses = expenses.reversed.take(5).toList().reversed.toList();

    Widget _buildSummaryCard(
      String title,
      String value,
      Color color,
      IconData icon,
    ) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildNotificationsSection({Widget? logoutButton}) {
      List<Widget> notifications = [];
      // Low stock notifications
      for (var item in lowStockItems) {
        notifications.add(
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text('Low stock: ${item.name}'),
            subtitle: Text('Only ${item.quantity} left in stock'),
          ),
        );
      }
      // Recent sales notifications
      for (var sale in recentSales) {
        notifications.add(
          ListTile(
            leading: const Icon(Icons.point_of_sale, color: Colors.green),
            title: Text('Sale recorded'),
            subtitle: Text('Amount: K${sale.grandTotal.toStringAsFixed(2)}'),
          ),
        );
      }
      // Recent expenses notifications
      for (var expense in recentExpenses) {
        notifications.add(
          ListTile(
            leading: const Icon(Icons.payments, color: Colors.red),
            title: Text('Expense recorded'),
            subtitle: Text('Amount: K${expense.amount.toStringAsFixed(2)}'),
          ),
        );
      }
      if (notifications.isEmpty) {
        notifications.add(
          const ListTile(
            leading: Icon(Icons.notifications_none),
            title: Text('No notifications'),
          ),
        );
      }
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (logoutButton != null) ...[const Spacer(), logoutButton],
                ],
              ),
              const Divider(),
              ...notifications,
            ],
          ),
        ),
      );
    }

    Widget _buildPremiumAd() {
      return isWindows(context)
          ? Card(
            elevation: 2,
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade700, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upgrade to Premium',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock advanced features, AI-powered reports, multi-shop management, and more!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Get Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          : Card(
            elevation: 2,
            color: Colors.green.shade50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Premium.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          );
    }

    Widget _buildLogoutButton({bool iconOnly = false}) {
      return iconOnly
          ? IconButton(
            icon: const Icon(Icons.logout, size: 20, color: Colors.grey),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Log out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await Provider.of<UsersProvider>(
                  context,
                  listen: false,
                ).logout();
              }
            },
          )
          : Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                label: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Log out'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await Provider.of<UsersProvider>(
                      context,
                      listen: false,
                    ).logout();
                  }
                },
              ),
            ),
          );
    }

    // Responsive layout
    if (isWindows(context)) {
      // Desktop layout
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            if (currentUser != null &&
                isPremium &&
                (currentUser.role == 'admin' || currentUser.role == 'manager'))
              IconButton(
                icon: const Icon(Icons.store),
                tooltip: 'Manage Shops',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShopManagementScreen(),
                    ),
                  );
                },
              ),
            if (currentUser != null &&
                (currentUser.role == 'admin' ||
                    currentUser.permissions.contains(
                      UserPermissions.manageSettings,
                    ) ||
                    currentUser.permissions.contains(UserPermissions.all)))
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white60, Colors.white70],
              ),
            ),
          ),
          actionsIconTheme: IconThemeData(color: Colors.green.shade700),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Overview & Premium
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildSummaryCard(
                              'Total Sales',
                              'K${totalSales.toStringAsFixed(2)}',
                              Colors.green,
                              Icons.point_of_sale,
                            ),
                            _buildSummaryCard(
                              'Total Expenses',
                              'K${totalExpenses.toStringAsFixed(2)}',
                              Colors.red,
                              Icons.payments,
                            ),
                            _buildSummaryCard(
                              'Net Profit',
                              'K${profit.toStringAsFixed(2)}',
                              profit >= 0 ? Colors.blue : Colors.orange,
                              Icons.trending_up,
                            ),
                            _buildSummaryCard(
                              'Stock Value',
                              'K${totalStockValue.toStringAsFixed(2)}',
                              Colors.purple,
                              Icons.inventory,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!isPremium) _buildPremiumAd(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Right: Notifications (with logout button in header)
                  Expanded(
                    flex: 1,
                    child: _buildNotificationsSection(
                      logoutButton: _buildLogoutButton(iconOnly: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile layout
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            if (currentUser != null &&
                isPremium &&
                (currentUser.role == 'admin' || currentUser.role == 'manager'))
              IconButton(
                icon: const Icon(Icons.store),
                tooltip: 'Manage Shops',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShopManagementScreen(),
                    ),
                  );
                },
              ),
            if (currentUser != null &&
                (currentUser.role == 'admin' ||
                    currentUser.permissions.contains(
                      UserPermissions.manageSettings,
                    ) ||
                    currentUser.permissions.contains(UserPermissions.all)))
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isPremium) _buildPremiumAd(),
              const SizedBox(height: 16),
              _buildNotificationsSection(),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSummaryCard(
                    'Sales',
                    'K${totalSales.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.point_of_sale,
                  ),
                  _buildSummaryCard(
                    'Expenses',
                    'K${totalExpenses.toStringAsFixed(2)}',
                    Colors.red,
                    Icons.payments,
                  ),
                  _buildSummaryCard(
                    'Profit',
                    'K${profit.toStringAsFixed(2)}',
                    profit >= 0 ? Colors.blue : Colors.orange,
                    Icons.trending_up,
                  ),
                  _buildSummaryCard(
                    'Stock',
                    'K${totalStockValue.toStringAsFixed(2)}',
                    Colors.purple,
                    Icons.inventory,
                  ),
                ],
              ),
              _buildLogoutButton(),
            ],
          ),
        ),
      );
    }
  }
}
