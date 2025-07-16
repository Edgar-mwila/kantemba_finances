import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/models/user.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:kantemba_finances/helpers/api_service.dart'; // Added for ApiService
import 'package:email_validator/email_validator.dart';

class BusinessSignUpScreen extends StatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  State<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends State<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessContactController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminContactController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _processing = false;

  String? _validateBusinessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a business name';
    }
    if (value.trim().length < 3) {
      return 'Business name must be at least 3 characters';
    }
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a contact';
    }
    final trimmed = value.trim();

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

  String? _validateAdminName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the admin name';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _processing = true;
      });

      try {
        // Show immediate feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creating your business...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        String businessId = await Provider.of<BusinessProvider>(
          context,
          listen: false,
        ).createBusiness(
          name: _businessNameController.text,
          // country: 'Zambia', // Fixed to Zambia
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
          name: _businessNameController.text,
          businessId: businessId,
        );
        debugPrint('Attempting to add shop: ${mainBranch.id}');

        try {
          await shopProvider.addShop(mainBranch);
          shopProvider.setCurrentShop(mainBranch);
          debugPrint('Shop added successfully: ${mainBranch.id}');
        } catch (e, stack) {
          debugPrint('Failed to add shop: $e');
          debugPrint('$stack');
          // Continue with signup even if shop creation fails
        }
        final user_id = DateTime.now().millisecondsSinceEpoch.toString();
        // Add admin as first user (with admin role and no shopId for global access)
        try {
          await Provider.of<UsersProvider>(context, listen: false).addUser(
            User(
              id: user_id,
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
        } catch (e) {
          debugPrint('Failed to add admin user: $e');
          // Continue with signup even if user creation fails
        }

        // Set current user as admin
        Provider.of<UsersProvider>(context, listen: false).setCurrentUser(
          User(
            id: user_id,
            name: _adminNameController.text,
            contact: _adminContactController.text,
            role: 'admin',
            permissions: [UserPermissions.all],
            shopId: null, // Admin has global access
            businessId: businessId,
          ),
        );

        await ApiService.saveToken('LocalLoginToken');

        if (mounted) {
          setState(() {
            _processing = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        debugPrint('Business signup error: $e');
        if (mounted) {
          setState(() {
            _processing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create business: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;
    if (isWindows(context)) {
      // Desktop layout: Centered, max width, two-column form
      return Scaffold(
        appBar: AppBar(
          title: const Text('Setup Your Business'),
          backgroundColor: green,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Setup Your Business',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _businessNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Business Name',
                                    ),
                                    validator: _validateBusinessName,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _businessContactController,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Business Contact (Zambian Phone or Email)',
                                      hintText:
                                          '+260XXXXXXXXX or email@example.com',
                                    ),
                                    validator: _validateContact,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _adminNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Admin Name',
                                    ),
                                    validator: _validateAdminName,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _adminContactController,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Admin Contact (Zambian Phone or Email)',
                                      hintText:
                                          '+260XXXXXXXXX or email@example.com',
                                    ),
                                    validator: _validateContact,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _adminPasswordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Admin Password',
                                    ),
                                    obscureText: true,
                                    validator: _validatePassword,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _processing ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                _processing
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text('Create Business'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile layout: Full screen, single column form
      return Scaffold(
        appBar: AppBar(
          title: const Text('Setup Your Business'),
          backgroundColor: green,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                  validator: _validateBusinessName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessContactController,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact (Zambian Phone or Email)',
                    hintText: '+260XXXXXXXXX or email@example.com',
                  ),
                  validator: _validateContact,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adminNameController,
                  decoration: const InputDecoration(labelText: 'Admin Name'),
                  validator: _validateAdminName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adminContactController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Contact (Zambian Phone or Email)',
                    hintText: '+260XXXXXXXXX or email@example.com',
                  ),
                  validator: _validateContact,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adminPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Password',
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _processing
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Create Business'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
