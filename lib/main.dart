import 'package:flutter/material.dart';
import 'package:kantemba_finances/screens/initial_choice_screen.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/screens/home_screen.dart';
import 'package:kantemba_finances/screens/inventory_screen.dart';
import 'package:kantemba_finances/screens/expenses_screen.dart';
import 'package:kantemba_finances/screens/reports_screen.dart';
import 'package:kantemba_finances/screens/manage_users_screen.dart';
import 'package:kantemba_finances/widgets/bottom_nav_bar.dart';
import 'package:kantemba_finances/providers/users_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => BusinessProvider()),
        ChangeNotifierProvider(create: (ctx) => UsersProvider()),
        ChangeNotifierProvider(create: (ctx) => SalesProvider()),
        ChangeNotifierProvider(create: (ctx) => ExpensesProvider()),
        ChangeNotifierProvider(create: (ctx) => InventoryProvider()),
      ],
      child: const KantembaFinancesApp(),
    ),
  );
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);

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

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    InventoryScreen(),
    ExpensesScreen(),
    ReportsScreen(),
    ManageUsersScreen(),
  ];

  static const List<String> _screenTitles = <String>[
    'Home',
    'Inventory',
    'Expenses',
    'Reports',
    'Manage Users',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        actions: [
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
