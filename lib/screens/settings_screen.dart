import 'package:flutter/material.dart';
import 'package:kantemba_finances/screens/settings/backup_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/security_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/tax_compliance_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/business_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/notifications_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/language_settings_screen.dart';
import 'package:kantemba_finances/screens/settings/help_support_screen.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              context,
              Icons.cloud_upload,
              'Data & Backup',
              'Manage your data backup and restore settings',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BackupSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.receipt_long,
              'Tax Compliance Settings',
              'Configure tax rates and compliance settings',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TaxComplianceSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.security,
              'Security Settings',
              'Manage app security and access controls',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.business,
              'Business Settings',
              'Manage business information and preferences',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BusinessSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.notifications,
              'Notifications',
              'Configure app notifications and alerts',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.language,
              'Language & Region',
              'Set your preferred language and region',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LanguageSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.help,
              'Help & Support',
              'Get help and contact support',
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.info,
              'About',
              'App version and information',
              () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Kantemba Finances',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Colors.green.shade700,
                  ),
                  children: [
                    const Text(
                      'A comprehensive business finance management app for tracking sales, expenses, inventory, and generating reports.',
                    ),
                  ],
                );
              },
            ),
            if (businessProvider.isPremium) ...[
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await SyncManager.batchSyncAndMarkSynced();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data synced to cloud!')),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
