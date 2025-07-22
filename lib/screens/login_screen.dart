import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:email_validator/email_validator.dart'; // For email validation

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userContactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter phone or email';
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final contact = _userContactController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final success = await usersProvider.login(context, contact, password);

      if (success) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Login failed, show error
        setState(() {
          _error = 'Invalid credentials. Please try again.';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = 'An error occurred: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;
    if (isWindows(context)) {
      // Desktop layout: Centered, max width, more padding
      return Scaffold(
        appBar: AppBar(title: const Text('Login'), backgroundColor: green),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
                      TextFormField(
                        controller: _userContactController,
                        decoration: const InputDecoration(
                          labelText: 'Phone or Email',
                        ),
                        validator: _validateContact,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 32),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Text(
                                'Log In',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Mobile layout (unchanged)
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), backgroundColor: green),
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
                  TextFormField(
                    controller: _userContactController,
                    decoration: const InputDecoration(
                      labelText: 'Phone or Email',
                    ),
                    validator: _validateContact,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text(
                            'Log In',
                            style: TextStyle(color: Colors.white),
                          ),
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
