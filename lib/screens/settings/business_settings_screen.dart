import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _countryController;
  late TextEditingController _adminNameController;
  late TextEditingController _adminContactController;

  @override
  void initState() {
    super.initState();
    final business = Provider.of<BusinessProvider>(context, listen: false);
    _nameController = TextEditingController(text: business.businessName ?? '');
    _contactController = TextEditingController(text: business.businessContact ?? '');
    _countryController = TextEditingController(text: business.country ?? '');
    _adminNameController = TextEditingController(text: business.adminName ?? '');
    _adminContactController = TextEditingController(text: business.adminContact ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _countryController.dispose();
    _adminNameController.dispose();
    _adminContactController.dispose();
    super.dispose();
  }

  Future<void> _saveBusiness() async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    business.businessName = _nameController.text;
    business.businessContact = _contactController.text;
    business.country = _countryController.text;
    business.adminName = _adminNameController.text;
    business.adminContact = _adminContactController.text;
    await business.updateBusiness(business);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business info saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Business Info', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
              ),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Business Contact'),
              ),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextFormField(
                controller: _adminNameController,
                decoration: const InputDecoration(labelText: 'Admin Name'),
              ),
              TextFormField(
                controller: _adminContactController,
                decoration: const InputDecoration(labelText: 'Admin Contact'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveBusiness,
                child: const Text('Save'),
              ),
              const SizedBox(height: 32),
              const Text('Subscription Status', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(business.isPremium ? 'Premium' : 'Free'),
                subtitle: business.isPremium && business.subscriptionExpiryDate != null
                    ? Text('Expires: ${business.subscriptionExpiryDate}')
                    : null,
                leading: Icon(
                  business.isPremium ? Icons.star : Icons.lock_open,
                  color: business.isPremium ? Colors.amber : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 