import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/models/user.dart';

class BusinessSignUpScreen extends StatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  State<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends State<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _townshipController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _countryController = TextEditingController();
  final _businessContactController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      String businessId = await Provider.of<BusinessProvider>(
        context,
        listen: false,
      ).createBusiness(
        name: _businessNameController.text,
        street: _streetController.text,
        township: _townshipController.text,
        city: _cityController.text,
        province: _provinceController.text,
        country: _countryController.text,
        businessContact: _businessContactController.text,
        ownerName: _ownerNameController.text,
        ownerContact: _ownerContactController.text,
      );
      // Add owner as first user
      await Provider.of<UsersProvider>(context, listen: false).addUser(
        User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _ownerNameController.text,
          role: UserRole.owner,
          permissions: [UserPermissions.all],
        ),
        _ownerPasswordController.text,
        _ownerContactController.text,
        businessId,
      );
      Provider.of<UsersProvider>(context, listen: false).setCurrentUser(
        User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _ownerNameController.text,
          role: UserRole.owner,
          permissions: [UserPermissions.all],
        ),
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
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
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please enter a business name'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Street'),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter a street' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _townshipController,
                  decoration: const InputDecoration(labelText: 'Township'),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter a township' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator:
                      (value) => value!.isEmpty ? 'Please enter a city' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Province/State',
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please enter a province/state'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter a country' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessContactController,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact (Phone + Country Code)',
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please enter a business contact'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(labelText: 'Owner Name'),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter the owner name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerContactController,
                  decoration: const InputDecoration(labelText: 'Owner Contact'),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Please enter the owner contact'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Password',
                  ),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter a password' : null,
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
