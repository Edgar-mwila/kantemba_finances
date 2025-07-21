import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I upgrade to premium?',
      'answer':
          'Go to the Premium screen and follow the instructions. Premium features include advanced reporting, unlimited employees, and priority support.',
    },
    {
      'question': 'How do I restore my data?',
      'answer':
          'Use the Backup & Data settings to import a backup. You can restore from JSON or CSV files.',
    },
    {
      'question': 'How do I add employees?',
      'answer':
          'Go to Employee Management in Settings. You can add employees and assign them to specific shops with different permission levels.',
    },
    {
      'question': 'How do I generate reports?',
      'answer':
          'Navigate to the Reports screen to access balance sheet, profit & loss, cash flow, and tax summary reports.',
    },
    {
      'question': 'How do I manage inventory?',
      'answer':
          'Use the Inventory screen to add, edit, and track your stock. You can also manage damaged goods and track stock levels.',
    },
    {
      'question': 'How do I record sales?',
      'answer':
          'Use the Sales screen to record new sales transactions. You can select items from inventory and calculate totals automatically.',
    },
    {
      'question': 'How do I track expenses?',
      'answer':
          'Use the Expenses screen to record business expenses. Categorize them for better reporting and analysis.',
    },
    {
      'question': 'How do I manage multiple shops?',
      'answer':
          'Go to Shop Management in Settings to add and manage multiple shop locations. Each shop can have its own inventory and sales.',
    },
  ];

  final List<Map<String, dynamic>> _contactMethods = [
    {
      'title': 'Email Support',
      'subtitle': 'Get detailed help via email',
      'icon': Icons.email,
      'color': Colors.blue,
      'action': 'support@kantemba.com',
    },
    {
      'title': 'WhatsApp Support',
      'subtitle': 'Quick help via WhatsApp',
      'icon': Icons.chat,
      'color': Colors.green,
      'action': '+260971234567',
    },
    {
      'title': 'Phone Support',
      'subtitle': 'Call us directly',
      'icon': Icons.phone,
      'color': Colors.orange,
      'action': '+260971234567',
    },
    {
      'title': 'Live Chat',
      'subtitle': 'Chat with support team',
      'icon': Icons.support_agent,
      'color': Colors.purple,
      'action': 'chat',
    },
  ];

  void _contactSupport(
    BuildContext context,
    Map<String, dynamic> method,
  ) async {
    switch (method['title']) {
      case 'Email Support':
        final email = Uri(
          scheme: 'mailto',
          path: method['action'],
          query: 'subject=Kantemba%20Finances%20Support',
        );
        if (await canLaunchUrl(email)) {
          await launchUrl(email);
        } else {
          _showErrorSnackBar('Could not open email app.');
        }
        break;
      case 'WhatsApp Support':
        final whatsapp = Uri.parse(
          'https://wa.me/${method['action']}?text=Hello%20Kantemba%20Support',
        );
        if (await canLaunchUrl(whatsapp)) {
          await launchUrl(whatsapp);
        } else {
          _showErrorSnackBar('Could not open WhatsApp.');
        }
        break;
      case 'Phone Support':
        final phone = Uri.parse('tel:${method['action']}');
        if (await canLaunchUrl(phone)) {
          await launchUrl(phone);
        } else {
          _showErrorSnackBar('Could not open phone app.');
        }
        break;
      case 'Live Chat':
        _showLiveChatDialog(context);
        break;
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Live Chat'),
            content: const Text(
              'Live chat is currently available during business hours (8 AM - 6 PM CAT). Please try again during these hours or use email support.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                Icon(icon, color: color ?? Colors.teal.shade700, size: 20),
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

  Widget _buildFAQItem(Map<String, String> faq) {
    return ExpansionTile(
      title: Text(
        faq['question']!,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            faq['answer']!,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildContactMethod(Map<String, dynamic> method) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _contactSupport(context, method),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(method['icon'], color: method['color'], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      method['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesList() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.book),
          title: const Text('User Manual'),
          subtitle: const Text('Complete guide to using the app'),
          onTap: () async {
            final url = 'https://www.kantemba.com/user_manual.pdf';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              _showErrorSnackBar('Could not open user manual.');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.video_library),
          title: const Text('Video Tutorials'),
          subtitle: const Text('Learn with step-by-step videos'),
          onTap: () async {
            final url = 'https://www.youtube.com/playlist?list=PLKantembaFinancesTutorials';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              _showErrorSnackBar('Could not open video tutorials.');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.forum),
          title: const Text('Community Forum'),
          subtitle: const Text('Connect with other users'),
          onTap: () async {
            final url = 'https://forum.kantemba.com';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              _showErrorSnackBar('Could not open community forum.');
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = isWindows(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FAQ Section
              _buildSettingCard(
                title: 'Frequently Asked Questions',
                icon: Icons.help,
                child: Column(
                  children: _faqs.map((faq) => _buildFAQItem(faq)).toList(),
                ),
              ),
              // Contact Support Section
              _buildSettingCard(
                title: 'Contact Support',
                icon: Icons.support_agent,
                child: Column(
                  children: _contactMethods
                      .map((method) => _buildContactMethod(method))
                      .toList(),
                ),
              ),
              // Resources Section
              _buildSettingCard(
                title: 'Resources',
                icon: Icons.library_books,
                child: _buildResourcesList(),
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // FAQ Section
              _buildSettingCard(
                title: 'Frequently Asked Questions',
                icon: Icons.help,
                child: Column(
                  children: _faqs.map((faq) => _buildFAQItem(faq)).toList(),
                ),
              ),
              // Contact Support Section
              _buildSettingCard(
                title: 'Contact Support',
                icon: Icons.support_agent,
                child: Column(
                  children: _contactMethods
                      .map((method) => _buildContactMethod(method))
                      .toList(),
                ),
              ),
              // Resources Section
              _buildSettingCard(
                title: 'Resources',
                icon: Icons.library_books,
                child: _buildResourcesList(),
              ),
            ],
          );

    if (isWindows(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Help & Support'),
          backgroundColor: Colors.teal.shade700,
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
                          const Icon(Icons.help, color: Colors.teal, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Help & Support',
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
          title: const Text('Help & Support'),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
}
