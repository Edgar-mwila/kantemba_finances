import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _salesNotif = true;
  bool _lowStockNotif = true;
  bool _expenseNotif = false;
  bool _reportNotif = false;
  bool _backupNotif = true;
  bool _securityNotif = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ledEnabled = false;
  String _notificationSound = 'default';
  String _notificationTime = 'immediate';
  bool _isLoading = false;

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
      _backupNotif = prefs.getBool('notif_backup') ?? true;
      _securityNotif = prefs.getBool('notif_security') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      _ledEnabled = prefs.getBool('notif_led') ?? false;
      _notificationSound = prefs.getString('notification_sound') ?? 'default';
      _notificationTime = prefs.getString('notification_time') ?? 'immediate';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_sales', _salesNotif);
      await prefs.setBool('notif_low_stock', _lowStockNotif);
      await prefs.setBool('notif_expense', _expenseNotif);
      await prefs.setBool('notif_report', _reportNotif);
      await prefs.setBool('notif_backup', _backupNotif);
      await prefs.setBool('notif_security', _securityNotif);
      await prefs.setBool('notif_sound', _soundEnabled);
      await prefs.setBool('notif_vibration', _vibrationEnabled);
      await prefs.setBool('notif_led', _ledEnabled);
      await prefs.setString('notification_sound', _notificationSound);
      await prefs.setString('notification_time', _notificationTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testNotification() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Business Notifications Section
        _buildSettingCard(
          title: 'Business Notifications',
          icon: Icons.business,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sales Notifications'),
                subtitle: const Text(
                  'Get notified of new sales and transactions',
                ),
                value: _salesNotif,
                onChanged: (value) => setState(() => _salesNotif = value),
                secondary: const Icon(Icons.point_of_sale),
              ),
              SwitchListTile(
                title: const Text('Low Stock Alerts'),
                subtitle: const Text(
                  'Get notified when inventory is running low',
                ),
                value: _lowStockNotif,
                onChanged: (value) => setState(() => _lowStockNotif = value),
                secondary: const Icon(Icons.inventory),
              ),
              SwitchListTile(
                title: const Text('Expense Notifications'),
                subtitle: const Text('Get notified of new expenses and costs'),
                value: _expenseNotif,
                onChanged: (value) => setState(() => _expenseNotif = value),
                secondary: const Icon(Icons.receipt),
              ),
              SwitchListTile(
                title: const Text('Report Notifications'),
                subtitle: const Text('Get notified when reports are ready'),
                value: _reportNotif,
                onChanged: (value) => setState(() => _reportNotif = value),
                secondary: const Icon(Icons.assessment),
              ),
            ],
          ),
        ),

        // System Notifications Section
        _buildSettingCard(
          title: 'System Notifications',
          icon: Icons.settings,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Backup Notifications'),
                subtitle: const Text('Get notified of backup status and sync'),
                value: _backupNotif,
                onChanged: (value) => setState(() => _backupNotif = value),
                secondary: const Icon(Icons.backup),
              ),
              SwitchListTile(
                title: const Text('Security Notifications'),
                subtitle: const Text(
                  'Get notified of security events and login attempts',
                ),
                value: _securityNotif,
                onChanged: (value) => setState(() => _securityNotif = value),
                secondary: const Icon(Icons.security),
              ),
            ],
          ),
        ),

        // Notification Preferences Section
        _buildSettingCard(
          title: 'Notification Preferences',
          icon: Icons.notifications,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
                secondary: const Icon(Icons.volume_up),
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate device for notifications'),
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
                secondary: const Icon(Icons.vibration),
              ),
              SwitchListTile(
                title: const Text('LED Light'),
                subtitle: const Text('Use LED light for notifications'),
                value: _ledEnabled,
                onChanged: (value) => setState(() => _ledEnabled = value),
                secondary: const Icon(Icons.lightbulb),
              ),
              ListTile(
                title: const Text('Notification Sound'),
                subtitle: Text(_notificationSound),
                trailing: DropdownButton<String>(
                  value: _notificationSound,
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default')),
                    DropdownMenuItem(value: 'chime', child: Text('Chime')),
                    DropdownMenuItem(value: 'bell', child: Text('Bell')),
                    DropdownMenuItem(value: 'none', child: Text('None')),
                  ],
                  onChanged:
                      (value) => setState(() => _notificationSound = value!),
                ),
              ),
              ListTile(
                title: const Text('Notification Timing'),
                subtitle: Text(_notificationTime),
                trailing: DropdownButton<String>(
                  value: _notificationTime,
                  items: const [
                    DropdownMenuItem(
                      value: 'immediate',
                      child: Text('Immediate'),
                    ),
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  ],
                  onChanged:
                      (value) => setState(() => _notificationTime = value!),
                ),
              ),
            ],
          ),
        ),

        // Test Notification Section
        _buildSettingCard(
          title: 'Test Notifications',
          icon: Icons.try_sms_star,
          child: Column(
            children: [
              const Text(
                'Test your notification settings to ensure they work correctly.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testNotification,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Send Test Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Save Notification Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );

    if (isWindows) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications Settings'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Notifications Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications Settings'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
}
