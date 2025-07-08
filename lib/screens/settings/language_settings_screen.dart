import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'Zambia';
  final List<String> _languages = ['English', 'French', 'Swahili'];
  final List<String> _regions = ['Zambia', 'Kenya', 'Nigeria', 'South Africa'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
      _selectedRegion = prefs.getString('app_region') ?? 'Zambia';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLanguage);
    await prefs.setString('app_region', _selectedRegion);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Language & region saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language & Region')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Language'),
            DropdownButton<String>(
              value: _selectedLanguage,
              items:
                  _languages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),
            const SizedBox(height: 24),
            const Text('Region/Currency'),
            DropdownButton<String>(
              value: _selectedRegion,
              items:
                  _regions
                      .map(
                        (reg) => DropdownMenuItem(value: reg, child: Text(reg)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedRegion = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveSettings, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
