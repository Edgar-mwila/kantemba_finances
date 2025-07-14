import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  String? _pin;
  bool _biometricEnabled = false;
  // bool _sessionTimeout = true;
  // bool _dataEncryption = true;
  // bool _showBalance = true;
  // bool _requirePinForTransactions = false;
  // int _sessionTimeoutMinutes = 30;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _showPin = false;
  // bool _isLoading = false;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pin = prefs.getString('app_pin');
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      // _sessionTimeout = prefs.getBool('session_timeout') ?? true;
      // _dataEncryption = prefs.getBool('data_encryption') ?? true;
      // _showBalance = prefs.getBool('show_balance') ?? true;
      // _requirePinForTransactions =
      //     prefs.getBool('require_pin_transactions') ?? false;
      // _sessionTimeoutMinutes = prefs.getInt('session_timeout_minutes') ?? 30;
    });
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove PIN'),
            content: const Text(
              'Are you sure you want to remove the PIN? This will disable PIN protection.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // setState(() => _isLoading = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('app_pin');
        setState(() => _pin = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing PIN: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // if (mounted) {
        //   setState(() => _isLoading = false);
        // }
      }
    }
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
                Icon(icon, color: color ?? Colors.red.shade700, size: 20),
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
    Widget content =
        isWindows(context)
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSettingCard(
                  title: 'PIN Protection',
                  icon: Icons.lock,
                  child: Column(
                    children: [
                      if (_pin == null) ...[
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: !_showPin,
                          decoration: InputDecoration(
                            labelText: 'Set 4-digit PIN',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.pin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPin
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () => setState(() => _showPin = !_showPin),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_pin != null) ...[
                        ListTile(
                          title: const Text('PIN Set'),
                          subtitle: const Text(
                            'Your account is protected by a PIN',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: _removePin,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildSettingCard(
                  title: 'Biometric Authentication',
                  icon: Icons.fingerprint,
                  child: SwitchListTile(
                    title: const Text('Enable Biometrics'),
                    subtitle: const Text('Use fingerprint or face unlock'),
                    value: _biometricEnabled,
                    onChanged:
                        (value) => setState(() => _biometricEnabled = value),
                    secondary: const Icon(Icons.fingerprint),
                  ),
                ),
                _buildSettingCard(
                  title: 'App Lock',
                  icon: Icons.lock_clock,
                  child: SwitchListTile(
                    title: const Text('Enable App Lock'),
                    subtitle: const Text('Lock app after inactivity'),
                    value: _appLockEnabled,
                    onChanged:
                        (value) => setState(() => _appLockEnabled = value),
                    secondary: const Icon(Icons.lock_clock),
                  ),
                ),
              ],
            )
            : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingCard(
                  title: 'PIN Protection',
                  icon: Icons.lock,
                  child: Column(
                    children: [
                      if (_pin == null) ...[
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: !_showPin,
                          decoration: InputDecoration(
                            labelText: 'Set 4-digit PIN',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.pin),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPin
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () => setState(() => _showPin = !_showPin),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_pin != null) ...[
                        ListTile(
                          title: const Text('PIN Set'),
                          subtitle: const Text(
                            'Your account is protected by a PIN',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: _removePin,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildSettingCard(
                  title: 'Biometric Authentication',
                  icon: Icons.fingerprint,
                  child: SwitchListTile(
                    title: const Text('Enable Biometrics'),
                    subtitle: const Text('Use fingerprint or face unlock'),
                    value: _biometricEnabled,
                    onChanged:
                        (value) => setState(() => _biometricEnabled = value),
                    secondary: const Icon(Icons.fingerprint),
                  ),
                ),
                _buildSettingCard(
                  title: 'App Lock',
                  icon: Icons.lock_clock,
                  child: SwitchListTile(
                    title: const Text('Enable App Lock'),
                    subtitle: const Text('Lock app after inactivity'),
                    value: _appLockEnabled,
                    onChanged:
                        (value) => setState(() => _appLockEnabled = value),
                    secondary: const Icon(Icons.lock_clock),
                  ),
                ),
              ],
            );

    if (isWindows(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Security Settings'),
          backgroundColor: Colors.red.shade700,
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
                            Icons.security,
                            color: Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Security Settings',
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
          title: const Text('Security Settings'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
}
