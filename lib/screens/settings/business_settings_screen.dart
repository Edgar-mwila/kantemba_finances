import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _adminNameController;
  late TextEditingController _adminContactController;
  late TextEditingController _addressController;
  late TextEditingController _taxNumberController;
  late TextEditingController _businessTypeController;

  bool _isLoading = false;
  bool _autoBackup = true;
  bool _syncEnabled = true;
  String _currency = 'ZMW';
  String _timezone = 'Africa/Lusaka';

  @override
  void initState() {
    super.initState();
    final business = Provider.of<BusinessProvider>(context, listen: false);
    _nameController = TextEditingController(text: business.businessName ?? '');
    _contactController = TextEditingController(
      text: business.businessContact ?? '',
    );
    _adminNameController = TextEditingController(
      text: business.adminName ?? '',
    );
    _adminContactController = TextEditingController(
      text: business.adminContact ?? '',
    );
    _addressController = TextEditingController();
    _taxNumberController = TextEditingController();
    _businessTypeController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _adminNameController.dispose();
    _adminContactController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('business_address') ?? '';
      _taxNumberController.text = prefs.getString('business_tax_number') ?? '';
      _businessTypeController.text = prefs.getString('business_type') ?? '';
      _autoBackup = prefs.getBool('auto_backup') ?? true;
      _syncEnabled = prefs.getBool('sync_enabled') ?? true;
      _currency = prefs.getString('business_currency') ?? 'ZMW';
      _timezone = prefs.getString('business_timezone') ?? 'Africa/Lusaka';
    });
  }

  String? _validateBusinessName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Enter business name';
    final trimmed = val.trim();
    if (trimmed.length < 3) return 'Name too short (min 3 chars)';
    if (trimmed.length > 50) return 'Name too long (max 50 chars)';
    final validPattern = RegExp(r'^[\w\s\-.,&()]+$');
    if (!validPattern.hasMatch(trimmed)) return 'Invalid characters';
    return null;
  }

  String? _validateContact(String? val) {
    if (val == null || val.trim().isEmpty) return 'Enter contact';
    final trimmed = val.trim();

    // Check if it's a valid email
    if (EmailValidator.validate(trimmed)) {
      return null;
    }

    // Check if it's a valid Zambian phone number
    if (isValidZambianPhoneNumber(trimmed)) {
      return null;
    }

    return 'Enter a valid Zambian phone number (+260XXXXXXXXX) or email address';
  }

  String? _validateAdminName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Enter admin name';
    final trimmed = val.trim();
    if (trimmed.length < 3) return 'Name too short (min 3 chars)';
    if (trimmed.length > 32) return 'Name too long (max 32 chars)';
    final validPattern = RegExp(r'^[A-Za-z\s]+$');
    if (!validPattern.hasMatch(trimmed)) return 'Invalid characters';
    return null;
  }

  String? _validateTaxNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional field
    final trimmed = val.trim();
    if (trimmed.length < 8) return 'Tax number too short';
    if (trimmed.length > 20) return 'Tax number too long';
    return null;
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final business = Provider.of<BusinessProvider>(context, listen: false);
      business.businessName = _nameController.text.trim();
      business.businessContact = _contactController.text.trim();
      business.country = 'Zambia'; // Fixed to Zambia
      business.adminName = _adminNameController.text.trim();
      business.adminContact = _adminContactController.text.trim();
      await business.updateBusinessHybrid(business);

      // Save additional settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_address', _addressController.text.trim());
      await prefs.setString(
        'business_tax_number',
        _taxNumberController.text.trim(),
      );
      await prefs.setString(
        'business_type',
        _businessTypeController.text.trim(),
      );
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setBool('sync_enabled', _syncEnabled);
      await prefs.setString('business_currency', _currency);
      await prefs.setString('business_timezone', _timezone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business settings saved successfully!'),
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
                Icon(icon, color: color ?? Colors.green.shade700, size: 20),
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
            ? Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Business Profile Section
                  _buildSettingCard(
                    title: 'Business Profile',
                    icon: Icons.business,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: _validateBusinessName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _businessTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Business Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                            hintText: 'e.g. Retail, Restaurant, Service',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Business Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Enter your business address',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _adminContactController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Contact *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            hintText: '+260XXXXXXXXX or email@example.com',
                          ),
                          validator: _validateContact,
                        ),
                      ],
                    ),
                  ),
                  // Business Settings Section
                  _buildSettingCard(
                    title: 'Business Settings',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Timezone'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _timezone,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Africa/Lusaka',
                                        child: Text('Lusaka (GMT+2)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'UTC',
                                        child: Text('UTC (GMT+0)'),
                                      ),
                                    ],
                                    onChanged:
                                        (value) =>
                                            setState(() => _timezone = value!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Auto Backup'),
                          subtitle: const Text(
                            'Automatically backup data to cloud',
                          ),
                          value: _autoBackup,
                          onChanged:
                              (value) => setState(() => _autoBackup = value),
                          secondary: const Icon(Icons.backup),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Business Profile Section
                  _buildSettingCard(
                    title: 'Business Profile',
                    icon: Icons.business,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: _validateBusinessName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _businessTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Business Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                            hintText: 'e.g. Retail, Restaurant, Service',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Business Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Enter your business address',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _adminContactController,
                          decoration: const InputDecoration(
                            labelText: 'Admin Contact *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                            hintText: '+260XXXXXXXXX or email@example.com',
                          ),
                          validator: _validateContact,
                        ),
                      ],
                    ),
                  ),
                  // Business Settings Section
                  _buildSettingCard(
                    title: 'Business Settings',
                    icon: Icons.settings,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Timezone'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _timezone,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Africa/Lusaka',
                                        child: Text('Lusaka (GMT+2)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'UTC',
                                        child: Text('UTC (GMT+0)'),
                                      ),
                                    ],
                                    onChanged:
                                        (value) =>
                                            setState(() => _timezone = value!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Auto Backup'),
                          subtitle: const Text(
                            'Automatically backup data to cloud',
                          ),
                          value: _autoBackup,
                          onChanged:
                              (value) => setState(() => _autoBackup = value),
                          secondary: const Icon(Icons.backup),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

    if (isWindows(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business Settings'),
          backgroundColor: Colors.green.shade700,
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
                            Icons.business,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Business Settings',
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
          title: const Text('Business Settings'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
}
