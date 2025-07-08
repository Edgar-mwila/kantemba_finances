import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  String? _pin;
  bool _biometricEnabled = false;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pin = prefs.getString('app_pin');
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _savePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', _pinController.text);
    setState(() {
      _pin = _pinController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN saved.')));
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App PIN', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                hintText: _pin == null ? 'Set 4-digit PIN' : 'Change PIN',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _savePin,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enable Biometric Unlock'),
                Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Biometric unlock is a demo. Real biometric support requires platform integration.'),
          ],
        ),
      ),
    );
  }
} 