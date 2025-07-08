import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kantemba_finances/screens/employee_management_screen.dart';
import 'package:kantemba_finances/screens/initial_choice_screen.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/screens/home_screen.dart';
import 'package:kantemba_finances/screens/inventory_screen.dart';
import 'package:kantemba_finances/screens/expenses_screen.dart';
import 'package:kantemba_finances/screens/reports_screen.dart';
import 'package:kantemba_finances/screens/shop_management_screen.dart';
import 'package:kantemba_finances/screens/settings_screen.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/screens/premium_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => BusinessProvider()),
        ChangeNotifierProvider(create: (ctx) => UsersProvider()),
        ChangeNotifierProvider(create: (ctx) => ShopProvider()),
        ChangeNotifierProvider(create: (ctx) => SalesProvider()),
        ChangeNotifierProvider(create: (ctx) => ExpensesProvider()),
        ChangeNotifierProvider(create: (ctx) => InventoryProvider()),
        ChangeNotifierProvider(create: (ctx) => ReturnsProvider()),
      ],
      child: const KantembaFinancesApp(),
    ),
  );
}

class NavItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final bool Function(User?) showFor;
  NavItem({
    required this.title,
    required this.icon,
    required this.screen,
    required this.showFor,
  });
}

class KantembaFinancesApp extends StatefulWidget {
  const KantembaFinancesApp({super.key});

  @override
  State<KantembaFinancesApp> createState() => _KantembaFinancesAppState();
}

class _KantembaFinancesAppState extends State<KantembaFinancesApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantemba Finances',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      if (result != ConnectivityResult.none) {
        final businessProvider = Provider.of<BusinessProvider>(
          context,
          listen: false,
        );
        if (businessProvider.isPremium) {
          await _syncAllToBackend(context, businessProvider);
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final expensesProvider = Provider.of<ExpensesProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final returnsProvider = Provider.of<ReturnsProvider>(
      context,
      listen: false,
    );
    await usersProvider.initialize(context);
    await businessProvider.fetchAndSetBusinessHybrid(businessProvider.id!);
    await usersProvider.fetchAndSetUsersHybrid(businessProvider);
    await shopProvider.fetchAndSetShopsHybrid(businessProvider);
    await salesProvider.fetchAndSetSalesHybrid(businessProvider);
    await expensesProvider.fetchAndSetExpensesHybrid(businessProvider);
    await inventoryProvider.fetchAndSetInventoryHybrid(businessProvider);
    await returnsProvider.fetchAndSetReturnsHybrid(businessProvider);
    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _syncAllToBackend(
    BuildContext context,
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) {
      await SyncManager.batchSyncAndMarkSynced();
      return;
    }
    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final expensesProvider = Provider.of<ExpensesProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final returnsProvider = Provider.of<ReturnsProvider>(
      context,
      listen: false,
    );
    await businessProvider.syncBusinessToBackend(batch: false);
    await usersProvider.syncUsersToBackend(businessProvider, batch: false);
    await shopProvider.syncShopsToBackend(businessProvider, batch: false);
    await salesProvider.syncSalesToBackend(businessProvider, batch: false);
    await expensesProvider.syncExpensesToBackend(
      businessProvider,
      batch: false,
    );
    await inventoryProvider.syncInventoryToBackend(
      businessProvider,
      batch: false,
    );
    await returnsProvider.syncReturnsToBackend(businessProvider, batch: false);
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);

    if (_isInitializing || !usersProvider.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 80,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                'Kantemba Finances',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (usersProvider.currentUser == null) {
      return const InitialChoiceScreen();
    }
    return const MainAppScreen();
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  List<NavItem> _navItemsForUser(User? user) {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final isPremium = businessProvider.isPremium;

    final allNavItems = [
      // Only show Shops for premium businesses
      if (isPremium)
        NavItem(
          title: 'Shops',
          icon: Icons.shopping_cart,
          screen: const ShopManagementScreen(),
          showFor:
              (u) =>
                  u != null &&
                  (u.permissions.contains(UserPermissions.all) ||
                      u.role == 'admin' ||
                      u.role == 'manager'),
        ),
      // Home is always available
      NavItem(
        title: 'Home',
        icon: Icons.home,
        screen: const HomeScreen(),
        showFor: (_) => true,
      ),
      // Inventory - available for users with inventory permissions
      NavItem(
        title: 'Inventory',
        icon: Icons.inventory,
        screen: const InventoryScreen(),
        showFor:
            (u) =>
                u != null &&
                (u.permissions.contains(UserPermissions.all) ||
                    u.permissions.contains(UserPermissions.viewInventory)),
      ),
      // Expenses - available for users with expenses permissions
      NavItem(
        title: 'Expenses',
        icon: Icons.money_off,
        screen: const ExpensesScreen(),
        showFor:
            (u) =>
                u != null &&
                (u.permissions.contains(UserPermissions.all) ||
                    u.permissions.contains(UserPermissions.viewExpenses)),
      ),
      // Reports - available for users with reports permissions
      NavItem(
        title: 'Reports',
        icon: Icons.bar_chart,
        screen: const ReportsScreen(),
        showFor:
            (u) =>
                u != null &&
                (u.permissions.contains(UserPermissions.all) ||
                    u.permissions.contains(UserPermissions.viewReports)),
      ),
      // Show Premium screen for non-premium businesses, Users for premium
      if (isPremium)
        NavItem(
          title: 'Users',
          icon: Icons.people,
          screen: const EmployeeManagementScreen(),
          showFor:
              (u) =>
                  u != null &&
                  (u.permissions.contains(UserPermissions.all) ||
                      u.permissions.contains(UserPermissions.manageUsers)),
        )
      else
        NavItem(
          title: 'Premium',
          icon: Icons.star,
          screen: const PremiumScreen(),
          showFor: (_) => true,
        ),
    ];

    // Filter items based on user permissions
    final filteredItems =
        allNavItems.where((item) => item.showFor(user)).toList();

    // Ensure we have at least 2 items (Home + Premium for non-premium, or Home + at least one other)
    if (filteredItems.length < 2) {
      // If we have less than 2 items, ensure we have Home and Premium (for non-premium)
      final essentialItems = <NavItem>[];

      // Always add Home
      essentialItems.add(
        NavItem(
          title: 'Home',
          icon: Icons.home,
          screen: const HomeScreen(),
          showFor: (_) => true,
        ),
      );

      // Add Premium for non-premium businesses
      if (!isPremium) {
        essentialItems.add(
          NavItem(
            title: 'Premium',
            icon: Icons.star,
            screen: const PremiumScreen(),
            showFor: (_) => true,
          ),
        );
      } else {
        // For premium businesses, add at least one other item if available
        final otherItems =
            filteredItems.where((item) => item.title != 'Home').toList();
        if (otherItems.isNotEmpty) {
          essentialItems.add(otherItems.first);
        } else {
          // Fallback to Premium screen even for premium businesses if no other items
          essentialItems.add(
            NavItem(
              title: 'Premium',
              icon: Icons.star,
              screen: const PremiumScreen(),
              showFor: (_) => true,
            ),
          );
        }
      }

      return essentialItems;
    }

    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    final businessProvider = Provider.of<BusinessProvider>(context);
    final currentUser = usersProvider.currentUser;
    final isPremium = businessProvider.isPremium;
    final navItems = _navItemsForUser(currentUser);

    // Ensure selected index is within bounds
    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(navItems[_selectedIndex].title),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
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
                await usersProvider.logout();
              }
            },
          ),
        ],
      ),
      body: navItems[_selectedIndex].screen,
      floatingActionButton: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final shops = shopProvider.shops;
          if (shops.length <= 1) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () async {
              final selectedShopId = await showDialog<String?>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Select Shop'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.all_inclusive),
                              title: const Text('All Shops'),
                              onTap: () => Navigator.of(ctx).pop(null),
                            ),
                            ...shops.map(
                              (shop) => ListTile(
                                leading: const Icon(Icons.store),
                                title: Text(shop.name),
                                onTap: () => Navigator.of(ctx).pop(shop.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              );
              final selectedShop =
                  selectedShopId == null
                      ? null
                      : shops.firstWhere(
                        (shop) => shop.id == selectedShopId,
                        orElse: () => shops.first,
                      );
              shopProvider.setCurrentShop(selectedShop);
            },
            tooltip: 'Change Shop',
            backgroundColor:
                shopProvider.currentShop != null
                    ? Colors.orange
                    : Theme.of(context).primaryColor,
            child: Icon(
              shopProvider.currentShop != null
                  ? Icons.filter_list
                  : Icons.store,
              color: Colors.white,
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items:
            navItems
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.title,
                  ),
                )
                .toList(),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
