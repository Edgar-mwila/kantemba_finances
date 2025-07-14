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
  bool _sessionTimeout = true;
  bool _dataEncryption = true;
  bool _showBalance = true;
  bool _requirePinForTransactions = false;
  int _sessionTimeoutMinutes = 30;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _showPin = false;
  bool _showConfirmPin = false;
  bool _isLoading = false;

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
      _sessionTimeout = prefs.getBool('session_timeout') ?? true;
      _dataEncryption = prefs.getBool('data_encryption') ?? true;
      _showBalance = prefs.getBool('show_balance') ?? true;
      _requirePinForTransactions = prefs.getBool('require_pin_transactions') ?? false;
      _sessionTimeoutMinutes = prefs.getInt('session_timeout_minutes') ?? 30;
    });
  }

  Future<void> _savePin() async {
    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN must be exactly 4 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_pin', _pinController.text);
      setState(() {
        _pin = _pinController.text;
        _pinController.clear();
        _confirmPinController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PIN: ${e.toString()}'),
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

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove the PIN? This will disable PIN protection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', value);
      setState(() => _biometricEnabled = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Biometric enabled' : 'Biometric disabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _saveSecuritySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_timeout', _sessionTimeout);
      await prefs.setBool('data_encryption', _dataEncryption);
      await prefs.setBool('show_balance', _showBalance);
      await prefs.setBool('require_pin_transactions', _requirePinForTransactions);
      await prefs.setInt('session_timeout_minutes', _sessionTimeoutMinutes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved!'),
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
    Widget content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PIN Protection Section
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
                      icon: Icon(_showPin ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showPin = !_showPin),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: !_showConfirmPin,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.pin),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPin ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showConfirmPin = !_showConfirmPin),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Set PIN'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'PIN is set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isLoading ? null : _removePin,
                      child: const Text('Remove PIN'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Biometric Section
        _buildSettingCard(
          title: 'Biometric Security',
          icon: Icons.fingerprint,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Biometric Unlock'),
                subtitle: const Text('Use fingerprint or face ID to unlock app'),
                value: _biometricEnabled,
                onChanged: _isLoading ? null : _toggleBiometric,
                secondary: const Icon(Icons.fingerprint),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Note: Biometric authentication requires device support and proper setup.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),

        // Session Security Section
        _buildSettingCard(
          title: 'Session Security',
          icon: Icons.timer,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Session Timeout'),
                subtitle: const Text('Automatically lock app after inactivity'),
                value: _sessionTimeout,
                onChanged: (value) => setState(() => _sessionTimeout = value),
                secondary: const Icon(Icons.timer),
              ),
              if (_sessionTimeout) ...[
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Timeout Duration'),
                  subtitle: Text('$_sessionTimeoutMinutes minutes'),
                  trailing: DropdownButton<int>(
                    value: _sessionTimeoutMinutes,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 min')),
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                    ],
                    onChanged: (value) => setState(() => _sessionTimeoutMinutes = value!),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Require PIN for Transactions'),
                subtitle: const Text('Ask for PIN before large transactions'),
                value: _requirePinForTransactions,
                onChanged: (value) => setState(() => _requirePinForTransactions = value),
                secondary: const Icon(Icons.payment),
              ),
            ],
          ),
        ),

        // Data Security Section
        _buildSettingCard(
          title: 'Data Security',
          icon: Icons.security,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Data Encryption'),
                subtitle: const Text('Encrypt sensitive data on device'),
                value: _dataEncryption,
                onChanged: (value) => setState(() => _dataEncryption = value),
                secondary: const Icon(Icons.enhanced_encryption),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Show Balance'),
                subtitle: const Text('Display account balances in app'),
                value: _showBalance,
                onChanged: (value) => setState(() => _showBalance = value),
                secondary: const Icon(Icons.account_balance_wallet),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSecuritySettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Security Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );

    if (isWindows) {
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
                          const Icon(Icons.security, color: Colors.red, size: 28),
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