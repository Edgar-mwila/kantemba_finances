import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

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
      final jsonString = jsonEncode(data);
      final output = await FilePicker.platform.getDirectoryPath();
      if (output == null) throw Exception('No directory selected');
      final file = File(
        '$output/kantemba_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);
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

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final data = await DBHelper.exportAllData();
      final output = await FilePicker.platform.getDirectoryPath();
      if (output == null) throw Exception('No directory selected');
      for (final table in data.keys) {
        final rows = data[table] as List<dynamic>;
        if (rows.isEmpty) continue;
        final headers =
            (rows.first as Map<String, dynamic>).keys
                .map((h) => h.toString())
                .toList();
        final csvRows = [
          headers,
          ...rows.map(
            (row) => headers.map((h) => row[h]?.toString() ?? '').toList(),
          ),
        ];
        final csvString = const ListToCsvConverter().convert(csvRows);
        final file = File(
          '$output/${table}_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        await file.writeAsString(csvString);
      }
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV export complete.')));
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV export failed.')));
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty)
        throw Exception('No file selected');
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      await DBHelper.importAllData(data);
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup imported from ${file.path}')),
      );
    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Import failed.')));
    }
  }

  Future<void> _importCsv() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty)
        throw Exception('No file selected');
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(content, eol: '\n');
      if (csvTable.isEmpty) throw Exception('CSV is empty');
      final headers = csvTable.first.cast<String>();
      final rows = csvTable.skip(1);
      // Infer table name from file name
      final fileName = file.uri.pathSegments.last;
      final table = fileName.split('_').first;
      for (final row in rows) {
        final Map<String, Object> rowMap = {};
        for (int i = 0; i < headers.length; i++) {
          rowMap[headers[i]] = row[i];
        }
        await DBHelper.insert(table, rowMap);
      }
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV imported into $table.')));
    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV import failed.')));
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
                  _isExporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.table_chart),
              label: const Text('Export as CSV'),
              onPressed: _isExporting ? null : _exportCsv,
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
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon:
                  _isImporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.upload_file),
              label: const Text('Import from CSV'),
              onPressed: _isImporting ? null : _importCsv,
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
