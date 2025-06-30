import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    InventoryScreen(),
    ExpensesScreen(),
    ReportsScreen(),
    ManageUsersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<UsersProvider>(context, listen: false).fetchAndSetUsers().then((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchAndSetItems();
      Provider.of<ExpensesProvider>(context, listen: false).fetchAndSetExpenses();
      Provider.of<SalesProvider>(context, listen: false).fetchAndSetSales();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
