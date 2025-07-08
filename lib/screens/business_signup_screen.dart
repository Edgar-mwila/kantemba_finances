import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/models/shop.dart';

class BusinessSignUpScreen extends StatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  State<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends State<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  // final _streetController = TextEditingController();
  // final _townshipController = TextEditingController();
  // final _cityController = TextEditingController();
  // final _provinceController = TextEditingController();
  final _countryController = TextEditingController();
  final _businessContactController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminContactController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      String businessId = await Provider.of<BusinessProvider>(
        context,
        listen: false,
      ).createBusiness(
        name: _businessNameController.text,
        // street: _streetController.text,
        // township: _townshipController.text,
        // city: _cityController.text,
        // province: _provinceController.text,
        country: _countryController.text,
        businessContact: _businessContactController.text,
        adminName: _adminNameController.text,
        adminContact: _adminContactController.text,
      );

      // Logging businessId
      debugPrint('Business created with ID: $businessId');

      // Create "Main Branch" shop for the business
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final mainBranch = Shop(
        id: '${businessId}_main_branch',
        name: 'Main Branch',
        // location: _countryController.text, // Use country as location for now
        businessId: businessId,
      );
      debugPrint('Attempting to add shop: ${mainBranch.id}');
      try {
        await shopProvider.addShop(mainBranch);
        debugPrint('Shop added successfully: ${mainBranch.id}');
      } catch (e, stack) {
        debugPrint('Failed to add shop: $e');
        debugPrint('$stack');
      }

      // Add admin as first user (with admin role and no shopId for global access)
      await Provider.of<UsersProvider>(context, listen: false).addUser(
        User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _adminNameController.text,
          contact: _adminContactController.text,
          role: 'admin',
          permissions: [UserPermissions.all],
          shopId: null, // Admin has global access, no specific shop
          businessId: businessId,
        ),
        _adminPasswordController.text,
        _adminContactController.text,
        businessId,
      );

      // Set current user as admin
      Provider.of<UsersProvider>(context, listen: false).setCurrentUser(
        User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _adminNameController.text,
          contact: _adminContactController.text,
          role: 'admin',
          permissions: [UserPermissions.all],
          shopId: null, // Admin has global access
          businessId: businessId,
        ),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: green, secondary: green),
                inputDecorationTheme: const InputDecorationTheme(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  labelStyle: TextStyle(color: Colors.green),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
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
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter a business name'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _streetController,
                  //   decoration: const InputDecoration(labelText: 'Street'),
                  //   validator:
                  //       (value) =>
                  //           value!.isEmpty ? 'Please enter a street' : null,
                  // ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _townshipController,
                  //   decoration: const InputDecoration(labelText: 'Township'),
                  //   validator:
                  //       (value) =>
                  //           value!.isEmpty ? 'Please enter a township' : null,
                  // ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _cityController,
                  //   decoration: const InputDecoration(labelText: 'City'),
                  //   validator:
                  //       (value) => value!.isEmpty ? 'Please enter a city' : null,
                  // ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _provinceController,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Province/State',
                  //   ),
                  //   validator:
                  //       (value) =>
                  //           value!.isEmpty
                  //               ? 'Please enter a province/state'
                  //               : null,
                  // ),
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
                    controller: _adminNameController,
                    decoration: const InputDecoration(labelText: 'admin Name'),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter the admin name'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminContactController,
                    decoration: const InputDecoration(
                      labelText: 'admin Contact',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter the admin contact'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adminPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'admin Password',
                    ),
                    obscureText: true,
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter a password' : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text(
                      'Complete Setup',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
