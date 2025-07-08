import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  String? _lastSyncTime;
  bool _isSyncing = false;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    // For demo: just use now or store in SharedPreferences for real
    setState(() {
      _lastSyncTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    final success = await SyncManager.batchSyncAndMarkSynced();
    setState(() => _isSyncing = false);
    if (success) {
      await _loadLastSyncTime();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data synced to cloud!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please try again.')),
      );
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final data = await DBHelper.exportAllData();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/kantemba_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(data.toString());
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup exported to ${file.path}')),
      );
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed.')));
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      // For demo: just restore from the latest backup file in app dir
      final dir = await getApplicationDocumentsDirectory();
      final files =
          Directory(
            dir.path,
          ).listSync().where((f) => f.path.endsWith('.json')).toList();
      if (files.isEmpty) throw Exception('No backup file found');
      final file = files.last as File;
      final content = await file.readAsString();
      // In real app, parse JSON
      // final data = jsonDecode(content);
      // await DBHelper.importAllData(data);
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup imported from ${file.path} (demo only)'),
        ),
      );
    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Import failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Cloud Sync:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _lastSyncTime ?? 'Never',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon:
                  _isSyncing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.cloud_upload),
              label: const Text('Sync Now (Cloud)'),
              onPressed: _isSyncing ? null : _syncNow,
            ),
            const Divider(height: 40),
            ElevatedButton.icon(
              icon:
                  _isExporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_alt),
              label: const Text('Export Data (Backup)'),
              onPressed: _isExporting ? null : _exportData,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon:
                  _isImporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.restore),
              label: const Text('Import Data (Restore)'),
              onPressed: _isImporting ? null : _importData,
            ),
            const SizedBox(height: 24),
            const Text(
              'Export/Import is a demo. In production, use JSON and file picker.',
            ),
          ],
        ),
      ),
    );
  }
}
