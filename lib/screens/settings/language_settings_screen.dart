import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'Zambia';
  String _selectedCurrency = 'ZMW';
  String _selectedDateFormat = 'DD/MM/YYYY';
  String _selectedTimeFormat = '24-hour';
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'sw', 'name': 'Swahili', 'native': 'Kiswahili'},
    {'code': 'fr', 'name': 'French', 'native': 'Français'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية'},
  ];

  final List<Map<String, String>> _regions = [
    {'code': 'ZM', 'name': 'Zambia', 'currency': 'ZMW', 'symbol': 'K'},
    {'code': 'KE', 'name': 'Kenya', 'currency': 'KES', 'symbol': 'KSh'},
    {'code': 'NG', 'name': 'Nigeria', 'currency': 'NGN', 'symbol': '₦'},
    {'code': 'ZA', 'name': 'South Africa', 'currency': 'ZAR', 'symbol': 'R'},
    {'code': 'TZ', 'name': 'Tanzania', 'currency': 'TZS', 'symbol': 'TSh'},
    {'code': 'UG', 'name': 'Uganda', 'currency': 'UGX', 'symbol': 'USh'},
  ];

  final List<String> _dateFormats = [
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'YYYY-MM-DD',
    'DD-MM-YYYY',
  ];

  final List<String> _timeFormats = ['12-hour', '24-hour'];

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
      _selectedCurrency = prefs.getString('app_currency') ?? 'ZMW';
      _selectedDateFormat = prefs.getString('date_format') ?? 'DD/MM/YYYY';
      _selectedTimeFormat = prefs.getString('time_format') ?? '24-hour';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', _selectedLanguage);
      await prefs.setString('app_region', _selectedRegion);
      await prefs.setString('app_currency', _selectedCurrency);
      await prefs.setString('date_format', _selectedDateFormat);
      await prefs.setString('time_format', _selectedTimeFormat);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language & region settings saved!'),
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

  void _updateCurrency() {
    final region = _regions.firstWhere(
      (r) => r['name'] == _selectedRegion,
      orElse: () => _regions.first,
    );
    setState(() {
      _selectedCurrency = region['currency']!;
    });
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
                Icon(icon, color: color ?? Colors.orange.shade700, size: 20),
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
    Widget content = isWindows(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSettingCard(
                title: 'Language',
                icon: Icons.language,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'App Language',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.translate),
                      ),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(
                          value: lang['name'],
                          child: Row(
                            children: [
                              Text(lang['name']!),
                              const SizedBox(width: 8),
                              Text(
                                '(${lang['native']!})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedLanguage = value!),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        'Language changes will take effect after restarting the app.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Region & Currency',
                icon: Icons.public,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem(
                          value: region['name'],
                          child: Text(region['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRegion = value!);
                        _updateCurrency();
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Currency: $_selectedCurrency',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Date & Time Format',
                icon: Icons.calendar_today,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDateFormat,
                      decoration: const InputDecoration(
                        labelText: 'Date Format',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      items: _dateFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDateFormat = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeFormat,
                      decoration: const InputDecoration(
                        labelText: 'Time Format',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      items: _timeFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTimeFormat = value!),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Localization Features',
                icon: Icons.settings,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-detect Region'),
                      subtitle: const Text('Automatically detect your region'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.location_searching),
                    ),
                    SwitchListTile(
                      title: const Text('Show Native Names'),
                      subtitle: const Text('Display names in native language'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.translate),
                    ),
                    SwitchListTile(
                      title: const Text('Currency Symbol'),
                      subtitle: const Text('Show currency symbols'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.attach_money),
                    ),
                  ],
                ),
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingCard(
                title: 'Language',
                icon: Icons.language,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'App Language',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.translate),
                      ),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(
                          value: lang['name'],
                          child: Row(
                            children: [
                              Text(lang['name']!),
                              const SizedBox(width: 8),
                              Text(
                                '(${lang['native']!})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedLanguage = value!),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        'Language changes will take effect after restarting the app.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Region & Currency',
                icon: Icons.public,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem(
                          value: region['name'],
                          child: Text(region['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRegion = value!);
                        _updateCurrency();
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Currency: $_selectedCurrency',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Date & Time Format',
                icon: Icons.calendar_today,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDateFormat,
                      decoration: const InputDecoration(
                        labelText: 'Date Format',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      items: _dateFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDateFormat = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeFormat,
                      decoration: const InputDecoration(
                        labelText: 'Time Format',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      items: _timeFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTimeFormat = value!),
                    ),
                  ],
                ),
              ),
              _buildSettingCard(
                title: 'Localization Features',
                icon: Icons.settings,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-detect Region'),
                      subtitle: const Text('Automatically detect your region'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.location_searching),
                    ),
                    SwitchListTile(
                      title: const Text('Show Native Names'),
                      subtitle: const Text('Display names in native language'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.translate),
                    ),
                    SwitchListTile(
                      title: const Text('Currency Symbol'),
                      subtitle: const Text('Show currency symbols'),
                      value: true,
                      onChanged: (value) {},
                      secondary: const Icon(Icons.attach_money),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (isWindows(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Language & Region'),
          backgroundColor: Colors.orange.shade700,
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
                            Icons.language,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Language & Region',
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
          title: const Text('Language & Region'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }

  String _getDatePreview() {
    final now = DateTime.now();
    switch (_selectedDateFormat) {
      case 'DD/MM/YYYY':
        return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      case 'MM/DD/YYYY':
        return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      case 'YYYY-MM-DD':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'DD-MM-YYYY':
        return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      default:
        return '${now.day}/${now.month}/${now.year}';
    }
  }

  String _getTimePreview() {
    final now = DateTime.now();
    switch (_selectedTimeFormat) {
      case '12-hour':
        final hour = now.hour > 12 ? now.hour - 12 : now.hour;
        final ampm = now.hour >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm';
      case '24-hour':
        return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      default:
        return '${now.hour}:${now.minute}';
    }
  }
}
