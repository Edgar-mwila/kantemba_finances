import 'dart:async';
import 'dart:io';

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
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:kantemba_finances/widgets/splash_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kantemba_finances/screens/dashboard_screen.dart';
import 'package:kantemba_finances/screens/pos_screen.dart';
import '../screens/debt_credit_screen.dart';
import 'package:kantemba_finances/providers/receivables_provider.dart';
import 'package:kantemba_finances/providers/payables_provider.dart';
import 'package:kantemba_finances/providers/loans_provider.dart';
import 'helpers/notification_helper.dart';
import 'helpers/analytics_service.dart';
import 'widgets/review_dialog.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AnalyticsService.initializeErrorHandling();
  AnalyticsService.logEvent('app_open');
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
        ChangeNotifierProvider(create: (ctx) => ReceivablesProvider()),
        ChangeNotifierProvider(create: (ctx) => PayablesProvider()),
        ChangeNotifierProvider(create: (ctx) => LoansProvider()),
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

class _KantembaFinancesAppState extends State<KantembaFinancesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationHelper.initialize(context);
      await _checkDueDates(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDueDates(context);
    }
  }

  Future<void> _checkDueDates(BuildContext context) async {
    final receivablesProvider = Provider.of<ReceivablesProvider>(
      context,
      listen: false,
    );
    final payablesProvider = Provider.of<PayablesProvider>(
      context,
      listen: false,
    );
    final loansProvider = Provider.of<LoansProvider>(context, listen: false);
    await receivablesProvider.fetchReceivables();
    await payablesProvider.fetchPayables();
    await loansProvider.fetchLoans();
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 3));
    int notifId = 1000;
    for (final r in receivablesProvider.receivables) {
      if (r.status == 'active' &&
          (r.dueDate.isBefore(soon) || r.dueDate.isBefore(now))) {
        final isOverdue = r.dueDate.isBefore(now);
        await NotificationHelper.showNotification(
          id: notifId++,
          title: isOverdue ? 'Receivable Overdue' : 'Receivable Due Soon',
          body:
              '${r.name} owes ${r.principal.toStringAsFixed(2)} due on ${r.dueDate.toLocal().toString().split(' ')[0]}',
        );
      }
    }
    for (final p in payablesProvider.payables) {
      if (p.status == 'active' &&
          (p.dueDate.isBefore(soon) || p.dueDate.isBefore(now))) {
        final isOverdue = p.dueDate.isBefore(now);
        await NotificationHelper.showNotification(
          id: notifId++,
          title: isOverdue ? 'Payable Overdue' : 'Payable Due Soon',
          body:
              '${p.name} is owed ${p.principal.toStringAsFixed(2)} due on ${p.dueDate.toLocal().toString().split(' ')[0]}',
        );
      }
    }
    for (final l in loansProvider.loans) {
      if (l.status == 'active' &&
          (l.dueDate.isBefore(soon) || l.dueDate.isBefore(now))) {
        final isOverdue = l.dueDate.isBefore(now);
        await NotificationHelper.showNotification(
          id: notifId++,
          title: isOverdue ? 'Loan Overdue' : 'Loan Due Soon',
          body:
              '${l.lenderName} loan of ${l.principal.toStringAsFixed(2)} due on ${l.dueDate.toLocal().toString().split(' ')[0]}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantemba Finances',
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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
    await usersProvider.initialize(context);
    // Add a small delay to ensure all providers are properly initialized
    await Future.delayed(const Duration(milliseconds: 100));
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
    await businessProvider.syncBusinessToBackend(batch: false);
    await SyncManager.batchSyncAndMarkSynced();
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);
    if (_isInitializing || !usersProvider.isInitialized) {
      return const SplashScreen();
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
  int _selectedIndex = 1;

  List<NavItem> _navItemsForUser(User? user) {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final isPremium = businessProvider.isPremium;

    final allNavItems = [
      NavItem(
        title: 'POS',
        icon: Icons.point_of_sale,
        screen: const PosScreen(),
        showFor: (user) => true,
      ),
      NavItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        screen: const DashboardScreen(),
        showFor:
            (u) =>
                u != null &&
                (u.role == 'admin' ||
                    u.role == 'manager' ||
                    (u.permissions.contains(UserPermissions.all) ||
                        u.permissions.contains(UserPermissions.viewReports))),
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
      NavItem(
        title: 'Debt/Credit',
        icon: Icons.account_balance_wallet,
        screen: const DebtAndCreditScreen(),
        showFor: (user) => user?.role == 'admin' || user?.role == 'manager',
      ),
    ];

    // Filter items based on user permissions
    final filteredItems =
        allNavItems.where((item) => item.showFor(user)).toList();

    // Ensure we have at least 2 items (Home + Premium for non-premium, or Home + at least one other)
    if (filteredItems.length < 2) {
      // If we have less than 2 items, ensure we have Home and Premium (for non-premium)
      final essentialItems = <NavItem>[];

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

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    AnalyticsService.logEvent(
      'navigate',
      data: {
        'screen':
            _navItemsForUser(
              Provider.of<UsersProvider>(context, listen: false).currentUser,
            )[index].title,
      },
    );
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

    if (isWindows(context)) {
      // Desktop layout with NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected:
                  (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations:
                  navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.title),
                        ),
                      )
                      .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Main content area
            Expanded(child: navItems[_selectedIndex].screen),
          ],
        ),
      );
    }

    // Mobile layout (unchanged)
    return Scaffold(
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
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
