import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/screens/home_screen.dart';
import 'package:provider/provider.dart';

class BusinessSignUpScreen extends StatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  State<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends State<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  bool _isMultiShop = false;
  bool _isVatRegistered = false;
  bool _isTurnoverTaxApplicable = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await Provider.of<BusinessProvider>(context, listen: false).setupBusiness(
        name: _businessNameController.text,
        multiShop: _isMultiShop,
        vatRegistered: _isVatRegistered,
        turnoverTaxApplicable: _isTurnoverTaxApplicable,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Setup Your Business',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a business name' : null,
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Enable Multi-Shop Support'),
                  value: _isMultiShop,
                  onChanged: (val) => setState(() => _isMultiShop = val),
                ),
                const SizedBox(height: 20),
                Text('Tax Settings', style: Theme.of(context).textTheme.titleLarge),
                 SwitchListTile(
                  title: const Text('Are you VAT registered?'),
                  value: _isVatRegistered,
                  onChanged: (val) => setState(() => _isVatRegistered = val),
                ),
                 SwitchListTile(
                  title: const Text('Is Turnover Tax applicable?'),
                  value: _isTurnoverTaxApplicable,
                  onChanged: (val) => setState(() => _isTurnoverTaxApplicable = val),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Complete Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 