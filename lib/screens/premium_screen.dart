import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../providers/business_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);

    if (isWindows) {
      // Desktop layout: Centered, max width, grid for features, more spacing
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade700, Colors.green.shade500],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Icon(Icons.star, size: 100, color: Colors.white),
                        const SizedBox(height: 15),
                        Text(
                          'Upgrade to Premium',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock the full potential of your business',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            businessProvider.businessName ?? 'Your Business',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Features Section
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Features',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Features grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 2.2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildFeatureCard(
                              context,
                              icon: Icons.psychology,
                              title: 'AI-Powered Financial Analysis',
                              description:
                                  'Get intelligent insights into your business performance with advanced AI analysis of complex financial reports.',
                              benefits: [
                                'Automated profit/loss analysis',
                                'Cash flow predictions',
                                'Trend identification',
                                'Smart recommendations',
                              ],
                              color: Colors.purple,
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.store,
                              title: 'Multi-Shop Management',
                              description:
                                  'Manage multiple locations from a single dashboard with centralized control and reporting.',
                              benefits: [
                                'Unlimited shop locations',
                                'Centralized inventory management',
                                'Cross-shop reporting',
                                'Location-specific analytics',
                              ],
                              color: Colors.blue,
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.people,
                              title: 'Advanced Employee Management',
                              description:
                                  'Hire and manage your team with role-based access control and performance tracking.',
                              benefits: [
                                'Unlimited employees',
                                'Role-based permissions',
                                'Performance tracking',
                                'Employee activity logs',
                              ],
                              color: Colors.orange,
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.cloud,
                              title: 'Cloud Storage & Backup',
                              description:
                                  'Secure cloud storage with automatic backups to protect your business data.',
                              benefits: [
                                'Automatic daily backups',
                                'Secure cloud storage',
                                'Data recovery options',
                                'Cross-device sync',
                              ],
                              color: Colors.green,
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.analytics,
                              title: 'Advanced Financial Reports',
                              description:
                                  'Comprehensive financial reports including balance sheets, cash flow statements, and tax summaries.',
                              benefits: [
                                'Balance sheet reports',
                                'Cash flow statements',
                                'Tax compliance reports',
                                'Custom report builder',
                              ],
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Pricing Section
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Premium Plan',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'K',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '99',
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '/month',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cancel anytime • 30-day free trial',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _showUpgradeDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Upgrade Now'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Contact Support
                        Center(
                          child: TextButton(
                            onPressed: () {
                              _showContactDialog(context);
                            },
                            child: Text(
                              'Contact Support',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile layout (unchanged)
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade700, Colors.green.shade500],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.star, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock the full potential of your business',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${businessProvider.businessName ?? 'Your Business'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Features',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI Analysis Feature
                  _buildFeatureCard(
                    context,
                    icon: Icons.psychology,
                    title: 'AI-Powered Financial Analysis',
                    description:
                        'Get intelligent insights into your business performance with advanced AI analysis of complex financial reports.',
                    benefits: [
                      'Automated profit/loss analysis',
                      'Cash flow predictions',
                      'Trend identification',
                      'Smart recommendations',
                    ],
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 20),

                  // Multi-Shop Management
                  _buildFeatureCard(
                    context,
                    icon: Icons.store,
                    title: 'Multi-Shop Management',
                    description:
                        'Manage multiple locations from a single dashboard with centralized control and reporting.',
                    benefits: [
                      'Unlimited shop locations',
                      'Centralized inventory management',
                      'Cross-shop reporting',
                      'Location-specific analytics',
                    ],
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 20),

                  // Employee Management
                  _buildFeatureCard(
                    context,
                    icon: Icons.people,
                    title: 'Advanced Employee Management',
                    description:
                        'Hire and manage your team with role-based access control and performance tracking.',
                    benefits: [
                      'Unlimited employees',
                      'Role-based permissions',
                      'Performance tracking',
                      'Employee activity logs',
                    ],
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 20),

                  // Cloud Storage & Backup
                  _buildFeatureCard(
                    context,
                    icon: Icons.cloud,
                    title: 'Cloud Storage & Backup',
                    description:
                        'Secure cloud storage with automatic backups to protect your business data.',
                    benefits: [
                      'Automatic daily backups',
                      'Secure cloud storage',
                      'Data recovery options',
                      'Cross-device sync',
                    ],
                    color: Colors.green,
                  ),

                  const SizedBox(height: 20),

                  // Advanced Reports
                  _buildFeatureCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Advanced Financial Reports',
                    description:
                        'Comprehensive financial reports including balance sheets, cash flow statements, and tax summaries.',
                    benefits: [
                      'Balance sheet reports',
                      'Cash flow statements',
                      'Tax compliance reports',
                      'Custom report builder',
                    ],
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 32),

                  // Pricing Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Premium Plan',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'K',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '99',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '/month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cancel anytime • 30-day free trial',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showUpgradeDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Start Free Trial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact Support
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showContactDialog(context);
                      },
                      child: Text(
                        'Contact Support',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> benefits,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Upgrade to Premium'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose a plan and payment method:'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startPayment(context, isYearly: false);
                  },
                  child: const Text('Monthly - USD 4.49 (Mobile Money/Card)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startPayment(context, isYearly: true);
                  },
                  child: const Text('Yearly - USD 49.99 (Mobile Money/Card)'),
                ),
                const SizedBox(height: 12),
                const Text('Includes 1 month free trial for new subscribers.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _startPayment(BuildContext context, {required bool isYearly}) async {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final currency = 'USD';
    final amount = isYearly ? '49.99' : '4.49';
    final txRef = 'Kantemba_${DateTime.now().millisecondsSinceEpoch}';
    final email = businessProvider.businessContact ?? 'user@kantemba.com';
    final name = businessProvider.businessName ?? 'Kantemba User';

    final Customer customer = Customer(
      name: name,
      phoneNumber: businessProvider.businessContact ?? '',
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey:
          "FLWPUBK_TEST-xxxxxxxxxxxxxxxxxxxxx-X", // TODO: Replace with your Flutterwave public key
      currency: currency,
      redirectUrl: "https://www.kantemba.com/payment-success",
      txRef: txRef,
      amount: amount,
      customer: customer,
      paymentOptions:
          "card, mobilemoneyzambia, mobilemoneyuganda, mobilemoneyghana, mobilemoneyfranco, mpesa, ussd",
      customization: Customization(title: "Kantemba Premium Subscription"),
      isTestMode: true, // Set to false in production
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      if (response.status == "success") {
        // Payment successful, upgrade to premium
        await _upgradeToPremium(context, isYearly: isYearly, txRef: txRef);
      } else if (response.status == "cancelled") {
        _showResultDialog(
          context,
          'Payment Cancelled',
          'You cancelled the payment.',
        );
      } else {
        _showResultDialog(
          context,
          'Payment Failed',
          response.status ?? 'Unknown error.',
        );
      }
    } catch (e) {
      _showResultDialog(context, 'Payment Error', e.toString());
    }
  }

  Future<void> _upgradeToPremium(
    BuildContext context, {
    required bool isYearly,
    required String txRef,
  }) async {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    // Show waiting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Verifying Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Please wait while we verify your payment...'),
              ],
            ),
          ),
    );
    // Poll backend for premium status
    bool upgraded = false;
    int attempts = 0;
    while (!upgraded && attempts < 10) {
      await Future.delayed(const Duration(seconds: 3));
      await businessProvider.setBusiness(businessProvider.id!);
      if (businessProvider.isPremium) {
        upgraded = true;
        break;
      }
      attempts++;
    }
    Navigator.of(context, rootNavigator: true).pop(); // Close waiting dialog
    if (upgraded) {
      await _syncAllToBackend(context, businessProvider);
      await SyncManager.batchSyncAndMarkSynced();
      _showRestartDialog(context);
    } else {
      _showResultDialog(
        context,
        'Upgrade Pending',
        'We could not verify your premium status yet. Please try again later.',
      );
    }
  }

  Future<void> _syncAllToBackend(
    BuildContext context,
    BusinessProvider businessProvider,
  ) async {
    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final expensesProvider = Provider.of<ExpensesProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final returnsProvider = Provider.of<ReturnsProvider>(
      context,
      listen: false,
    );
    await businessProvider.syncBusinessToBackend();
    await usersProvider.syncUsersToBackend(businessProvider);
    await shopProvider.syncShopsToBackend(businessProvider);
    await salesProvider.syncSalesToBackend(businessProvider);
    await expensesProvider.syncExpensesToBackend(businessProvider);
    await inventoryProvider.syncInventoryToBackend(businessProvider);
    await returnsProvider.syncReturnsToBackend(businessProvider);
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Upgrade Complete'),
            content: const Text(
              'Your business is now premium! The app will restart to enable premium features.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Restart the app
                  await Future.delayed(const Duration(milliseconds: 500));
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                },
                child: const Text('Restart Now'),
              ),
            ],
          ),
    );
  }

  void _showResultDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Contact Support'),
            content: const Text(
              'For premium upgrades and support, please contact us at:\n\nsupport@kantemba.com\n+260 955 123 456',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
