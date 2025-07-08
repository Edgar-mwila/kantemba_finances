import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _salesNotif = false;
  bool _lowStockNotif = false;
  bool _expenseNotif = false;
  bool _reportNotif = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _salesNotif = prefs.getBool('notif_sales') ?? true;
      _lowStockNotif = prefs.getBool('notif_low_stock') ?? true;
      _expenseNotif = prefs.getBool('notif_expense') ?? false;
      _reportNotif = prefs.getBool('notif_report') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_sales', _salesNotif);
    await prefs.setBool('notif_low_stock', _lowStockNotif);
    await prefs.setBool('notif_expense', _expenseNotif);
    await prefs.setBool('notif_report', _reportNotif);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Settings'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Sales Notifications'),
              value: _salesNotif,
              onChanged: (v) => setState(() => _salesNotif = v),
            ),
            SwitchListTile(
              title: const Text('Low Stock Alerts'),
              value: _lowStockNotif,
              onChanged: (v) => setState(() => _lowStockNotif = v),
            ),
            SwitchListTile(
              title: const Text('Expense Notifications'),
              value: _expenseNotif,
              onChanged: (v) => setState(() => _expenseNotif = v),
            ),
            SwitchListTile(
              title: const Text('Report Notifications'),
              value: _reportNotif,
              onChanged: (v) => setState(() => _reportNotif = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
} 