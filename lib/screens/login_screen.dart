import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessIdController = TextEditingController();
  final _userContactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

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
    final businessId = _businessIdController.text.trim();
    final contact = _userContactController.text.trim();
    final password = _passwordController.text.trim();

    await usersProvider
        .login(context, businessId, contact, password)
        .then((success) {
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
        })
        .catchError((error) {
          setState(() {
            _error = 'An error occurred: $error';
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;
    if (isWindows) {
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
                      Text(
                        'Login',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _businessIdController,
                        decoration: const InputDecoration(
                          labelText: 'Business ID',
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter business ID'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _userContactController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter phone'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Enter password'
                                    : null,
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
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _businessIdController,
                    decoration: const InputDecoration(labelText: 'Business ID'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter business ID'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userContactController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter phone'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter password'
                                : null,
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
