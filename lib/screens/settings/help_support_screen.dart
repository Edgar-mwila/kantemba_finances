import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _contactSupport(BuildContext context) async {
    final email = Uri(
      scheme: 'mailto',
      path: 'support@kantemba.com',
      query: 'subject=Kantemba%20Finances%20Support',
    );
    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  void _contactWhatsApp(BuildContext context) async {
    final whatsapp = Uri.parse(
      'https://wa.me/260971234567?text=Hello%20Kantemba%20Support',
    );
    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Q: How do I upgrade to premium?\nA: Go to the Premium screen and follow the instructions.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Q: How do I restore my data?\nA: Use the Backup & Data settings to import a backup.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Contact Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.email),
          label: const Text('Email Support'),
          onPressed: () => _contactSupport(context),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('WhatsApp Support'),
          onPressed: () => _contactWhatsApp(context),
        ),
        const SizedBox(height: 24),
        const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Kantemba Finances v1.0.0\nA comprehensive business finance management app.',
        ),
      ],
    );

    if (isWindows) {
      // Desktop: Center, max width, two-column layout for FAQ and support actions
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FAQ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Frequently Asked Questions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Q: How do I upgrade to premium?\nA: Go to the Premium screen and follow the instructions.',
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Q: How do I restore my data?\nA: Use the Backup & Data settings to import a backup.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Contact/Support
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Support',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.email),
                                label: const Text('Email Support'),
                                onPressed: () => _contactSupport(context),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.chat),
                                label: const Text('WhatsApp Support'),
                                onPressed: () => _contactWhatsApp(context),
                              ),
                              const SizedBox(height: 24),
                              const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                'Kantemba Finances v1.0.0\nA comprehensive business finance management app.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Q: How do I upgrade to premium?\nA: Go to the Premium screen and follow the instructions.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Q: How do I restore my data?\nA: Use the Backup & Data settings to import a backup.',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Contact Support',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.email),
                          label: const Text('Email Support'),
                          onPressed: () => _contactSupport(context),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp Support'),
                          onPressed: () => _contactWhatsApp(context),
                        ),
                        const SizedBox(height: 24),
                        const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Kantemba Finances v1.0.0\nA comprehensive business finance management app.',
                        ),
                      ],
                    );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: content,
    );
  }
}
