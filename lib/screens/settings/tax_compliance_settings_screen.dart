import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class TaxComplianceSettingsScreen extends StatefulWidget {
  const TaxComplianceSettingsScreen({super.key});

  @override
  State<TaxComplianceSettingsScreen> createState() => _TaxComplianceSettingsScreenState();
}

class _TaxComplianceSettingsScreenState extends State<TaxComplianceSettingsScreen> {
  final _vatController = TextEditingController();
  final _turnoverController = TextEditingController();
  final _levyController = TextEditingController();
  final _incomeTaxController = TextEditingController();
  final _withholdingTaxController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _autoCalculateTax = true;
  bool _includeTaxInPrices = false;
  bool _showTaxBreakdown = true;
  bool _taxExempt = false;
  String _taxPeriod = 'monthly';
  String _taxAuthority = 'ZRA';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _vatController.dispose();
    _turnoverController.dispose();
    _levyController.dispose();
    _incomeTaxController.dispose();
    _withholdingTaxController.dispose();
    _taxNumberController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vatController.text = (prefs.getDouble('vat_rate') ?? 16.0).toString();
      _turnoverController.text = (prefs.getDouble('turnover_rate') ?? 4.0).toString();
      _levyController.text = (prefs.getDouble('levy_rate') ?? 1.5).toString();
      _incomeTaxController.text = (prefs.getDouble('income_tax_rate') ?? 30.0).toString();
      _withholdingTaxController.text = (prefs.getDouble('withholding_tax_rate') ?? 15.0).toString();
      _taxNumberController.text = prefs.getString('tax_number') ?? '';
      _businessNameController.text = prefs.getString('business_name_tax') ?? '';
      _autoCalculateTax = prefs.getBool('auto_calculate_tax') ?? true;
      _includeTaxInPrices = prefs.getBool('include_tax_in_prices') ?? false;
      _showTaxBreakdown = prefs.getBool('show_tax_breakdown') ?? true;
      _taxExempt = prefs.getBool('tax_exempt') ?? false;
      _taxPeriod = prefs.getString('tax_period') ?? 'monthly';
      _taxAuthority = prefs.getString('tax_authority') ?? 'ZRA';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('vat_rate', double.tryParse(_vatController.text) ?? 16.0);
      await prefs.setDouble('turnover_rate', double.tryParse(_turnoverController.text) ?? 4.0);
      await prefs.setDouble('levy_rate', double.tryParse(_levyController.text) ?? 1.5);
      await prefs.setDouble('income_tax_rate', double.tryParse(_incomeTaxController.text) ?? 30.0);
      await prefs.setDouble('withholding_tax_rate', double.tryParse(_withholdingTaxController.text) ?? 15.0);
      await prefs.setString('tax_number', _taxNumberController.text.trim());
      await prefs.setString('business_name_tax', _businessNameController.text.trim());
      await prefs.setBool('auto_calculate_tax', _autoCalculateTax);
      await prefs.setBool('include_tax_in_prices', _includeTaxInPrices);
      await prefs.setBool('show_tax_breakdown', _showTaxBreakdown);
      await prefs.setBool('tax_exempt', _taxExempt);
      await prefs.setString('tax_period', _taxPeriod);
      await prefs.setString('tax_authority', _taxAuthority);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings saved successfully!'),
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

  String? _validateTaxRate(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a value';
    final rate = double.tryParse(value);
    if (rate == null) return 'Please enter a valid number';
    if (rate < 0 || rate > 100) return 'Rate must be between 0 and 100';
    return null;
  }

  String? _validateTaxNumber(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    if (value.length < 8) return 'Tax number too short';
    if (value.length > 20) return 'Tax number too long';
    return null;
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
                Icon(icon, color: color ?? Colors.purple.shade700, size: 20),
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
        // Business Information Section
        _buildSettingCard(
          title: 'Business Information',
          icon: Icons.business,
          child: Column(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name for Tax',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                  hintText: 'Enter business name as registered with tax authority',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Registration Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                  hintText: 'e.g. ZRA123456789',
                ),
                validator: _validateTaxNumber,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tax Authority'),
                subtitle: Text(_taxAuthority),
                trailing: DropdownButton<String>(
                  value: _taxAuthority,
                  items: const [
                    DropdownMenuItem(value: 'ZRA', child: Text('ZRA (Zambia)')),
                    DropdownMenuItem(value: 'KRA', child: Text('KRA (Kenya)')),
                    DropdownMenuItem(value: 'FIRS', child: Text('FIRS (Nigeria)')),
                    DropdownMenuItem(value: 'SARS', child: Text('SARS (South Africa)')),
                  ],
                  onChanged: (value) => setState(() => _taxAuthority = value!),
                ),
              ),
            ],
          ),
        ),

        // Tax Rates Section
        _buildSettingCard(
          title: 'Tax Rates',
          icon: Icons.calculate,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'VAT Rate (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                        hintText: 'e.g. 16',
                      ),
                      validator: _validateTaxRate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _turnoverController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Turnover Tax (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                        hintText: 'e.g. 4',
                      ),
                      validator: _validateTaxRate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _levyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Levy Rate (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                        hintText: 'e.g. 1.5',
                      ),
                      validator: _validateTaxRate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _incomeTaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Income Tax (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        hintText: 'e.g. 30',
                      ),
                      validator: _validateTaxRate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _withholdingTaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Withholding Tax (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money_off),
                  hintText: 'e.g. 15',
                ),
                validator: _validateTaxRate,
              ),
            ],
          ),
        ),

        // Tax Settings Section
        _buildSettingCard(
          title: 'Tax Settings',
          icon: Icons.settings,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto Calculate Tax'),
                subtitle: const Text('Automatically calculate tax on transactions'),
                value: _autoCalculateTax,
                onChanged: (value) => setState(() => _autoCalculateTax = value),
                secondary: const Icon(Icons.calculate),
              ),
              SwitchListTile(
                title: const Text('Include Tax in Prices'),
                subtitle: const Text('Show prices inclusive of tax'),
                value: _includeTaxInPrices,
                onChanged: (value) => setState(() => _includeTaxInPrices = value),
                secondary: const Icon(Icons.attach_money),
              ),
              SwitchListTile(
                title: const Text('Show Tax Breakdown'),
                subtitle: const Text('Display detailed tax breakdown in reports'),
                value: _showTaxBreakdown,
                onChanged: (value) => setState(() => _showTaxBreakdown = value),
                secondary: const Icon(Icons.receipt),
              ),
              SwitchListTile(
                title: const Text('Tax Exempt'),
                subtitle: const Text('Business is exempt from certain taxes'),
                value: _taxExempt,
                onChanged: (value) => setState(() => _taxExempt = value),
                secondary: const Icon(Icons.block),
              ),
              ListTile(
                title: const Text('Tax Period'),
                subtitle: Text(_taxPeriod),
                trailing: DropdownButton<String>(
                  value: _taxPeriod,
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'annually', child: Text('Annually')),
                  ],
                  onChanged: (value) => setState(() => _taxPeriod = value!),
                ),
              ),
            ],
          ),
        ),

        // Tax Summary Section
        _buildSettingCard(
          title: 'Tax Summary',
          icon: Icons.assessment,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Tax Configuration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('VAT Rate: ${_vatController.text}%'),
                    Text('Turnover Tax: ${_turnoverController.text}%'),
                    Text('Levy Rate: ${_levyController.text}%'),
                    Text('Income Tax: ${_incomeTaxController.text}%'),
                    Text('Withholding Tax: ${_withholdingTaxController.text}%'),
                    const SizedBox(height: 8),
                    Text('Tax Period: ${_taxPeriod}'),
                    Text('Tax Authority: $_taxAuthority'),
                    if (_taxExempt)
                      const Text(
                        'Status: Tax Exempt',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
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
              backgroundColor: Colors.purple.shade700,
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
                    'Save Tax Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );

    if (isWindows) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tax Compliance Settings'),
          backgroundColor: Colors.purple.shade700,
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
                          const Icon(Icons.receipt_long, color: Colors.purple, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Tax Compliance Settings',
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
          title: const Text('Tax Compliance Settings'),
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
} 