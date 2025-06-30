import 'package:flutter/material.dart';

class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: const Center(
        child: Text('Data and backup settings will be configured here.'),
      ),
    );
  }
} 