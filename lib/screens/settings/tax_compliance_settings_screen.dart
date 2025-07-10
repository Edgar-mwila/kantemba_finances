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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vatController.text = (prefs.getDouble('vat_rate') ?? 0.0).toString();
      _turnoverController.text = (prefs.getDouble('turnover_rate') ?? 0.0).toString();
      _levyController.text = (prefs.getDouble('levy_rate') ?? 0.0).toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('vat_rate', double.tryParse(_vatController.text) ?? 0.0);
    await prefs.setDouble('turnover_rate', double.tryParse(_turnoverController.text) ?? 0.0);
    await prefs.setDouble('levy_rate', double.tryParse(_levyController.text) ?? 0.0);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tax settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VAT Rate (%)'),
        TextField(
          controller: _vatController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 16'),
        ),
        const SizedBox(height: 16),
        const Text('Turnover Tax Rate (%)'),
        TextField(
          controller: _turnoverController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 4'),
        ),
        const SizedBox(height: 16),
        const Text('Levy Rate (%)'),
        TextField(
          controller: _levyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 1.5'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );

    if (isWindows) {
      // Desktop: Center, max width, two-column layout for tax fields
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('VAT Rate (%)'),
                                  TextField(
                                    controller: _vatController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'e.g. 16'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Turnover Tax Rate (%)'),
                                  TextField(
                                    controller: _turnoverController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'e.g. 4'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VAT Rate (%)'),
                            TextField(
                              controller: _vatController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 16'),
                            ),
                            const SizedBox(height: 16),
                            const Text('Turnover Tax Rate (%)'),
                            TextField(
                              controller: _turnoverController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 4'),
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  const Text('Levy Rate (%)'),
                  TextField(
                    controller: _levyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 1.5'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tax Compliance Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
} 