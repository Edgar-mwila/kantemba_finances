import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/sync_manager.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  String? _lastSyncTime;
  String? _lastBackupTime;
  bool _isSyncing = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _autoBackup = true;
  bool _cloudSync = true;
  String _backupFrequency = 'daily';
  double _syncProgress = 0.0;
  double _backupProgress = 0.0;
  String _currentOperation = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSyncTime = prefs.getString('last_sync_time') ?? 'Never';
      _lastBackupTime = prefs.getString('last_backup_time') ?? 'Never';
      _autoBackup = prefs.getBool('auto_backup') ?? true;
      _cloudSync = prefs.getBool('cloud_sync') ?? true;
      _backupFrequency = prefs.getString('backup_frequency') ?? 'daily';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup', _autoBackup);
    await prefs.setBool('cloud_sync', _cloudSync);
    await prefs.setString('backup_frequency', _backupFrequency);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup settings saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
      _currentOperation = 'Syncing to cloud...';
      _syncProgress = 0.0;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _syncProgress = i / 10;
        });
      }

      final success = await SyncManager.batchSyncAndMarkSynced();

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
        await prefs.setString('last_sync_time', now);

        setState(() {
          _lastSyncTime = now;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data synced to cloud successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Sync failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _currentOperation = '';
          _syncProgress = 0.0;
        });
      }
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _currentOperation = 'Exporting data...';
      _backupProgress = 0.0;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() {
          _backupProgress = i / 10;
        });
      }

      final data = await DBHelper.exportAllData();
      final jsonString = jsonEncode(data);
      final output = await FilePicker.platform.getDirectoryPath();

      if (output == null) throw Exception('No directory selected');

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('$output/kantemba_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      final prefs = await SharedPreferences.getInstance();
      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      await prefs.setString('last_backup_time', now);

      setState(() {
        _lastBackupTime = now;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup exported to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentOperation = '';
          _backupProgress = 0.0;
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
      _currentOperation = 'Exporting CSV...';
      _backupProgress = 0.0;
    });

    try {
      final data = await DBHelper.exportAllData();
      final output = await FilePicker.platform.getDirectoryPath();

      if (output == null) throw Exception('No directory selected');

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      int tableCount = 0;
      final totalTables = data.keys.length;

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
        final file = File('$output/${table}_$timestamp.csv');
        await file.writeAsString(csvString);

        tableCount++;
        setState(() {
          _backupProgress = tableCount / totalTables;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentOperation = '';
          _backupProgress = 0.0;
        });
      }
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
      _currentOperation = 'Importing data...';
      _backupProgress = 0.0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Simulate progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _backupProgress = i / 10;
        });
      }

      await DBHelper.importAllData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup imported from ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _currentOperation = '';
          _backupProgress = 0.0;
        });
      }
    }
  }

  Future<void> _importCsv() async {
    setState(() {
      _isImporting = true;
      _currentOperation = 'Importing CSV...';
      _backupProgress = 0.0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(content, eol: '\n');

      if (csvTable.isEmpty) throw Exception('CSV is empty');

      final headers = csvTable.first.cast<String>();
      final rows = csvTable.skip(1);
      final fileName = file.uri.pathSegments.last;
      final table = fileName.split('_').first;

      int rowCount = 0;
      final totalRows = rows.length;

      for (final row in rows) {
        final Map<String, Object> rowMap = {};
        for (int i = 0; i < headers.length; i++) {
          rowMap[headers[i]] = row[i];
        }
        await DBHelper.insert(table, rowMap);

        rowCount++;
        setState(() {
          _backupProgress = rowCount / totalRows;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV imported into $table successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _currentOperation = '';
          _backupProgress = 0.0;
        });
      }
    }
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color ?? Colors.green.shade700, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Indicator
        if (_isSyncing || _isExporting || _isImporting) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentOperation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _isSyncing ? _syncProgress : _backupProgress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isSyncing ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Cloud Sync Section
        const Text(
          'Cloud Sync',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Sync to Cloud',
          subtitle: 'Upload data to secure cloud storage',
          icon: Icons.cloud_upload,
          onPressed: _syncNow,
          isLoading: _isSyncing,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),

        // Local Backup Section
        const Text(
          'Local Backup',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Export Data (JSON)',
          subtitle: 'Create a complete backup file',
          icon: Icons.save_alt,
          onPressed: _exportData,
          isLoading: _isExporting,
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildActionCard(
          title: 'Export as CSV',
          subtitle: 'Export data in spreadsheet format',
          icon: Icons.table_chart,
          onPressed: _exportCsv,
          isLoading: _isExporting,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),

        // Restore Section
        const Text(
          'Restore Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Import from JSON',
          subtitle: 'Restore from backup file',
          icon: Icons.restore,
          onPressed: _importData,
          isLoading: _isImporting,
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        _buildActionCard(
          title: 'Import from CSV',
          subtitle: 'Import data from spreadsheet',
          icon: Icons.upload_file,
          onPressed: _importCsv,
          isLoading: _isImporting,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backup Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Auto Backup'),
          subtitle: const Text('Automatically backup data'),
          value: _autoBackup,
          onChanged: (value) => setState(() => _autoBackup = value),
          secondary: const Icon(Icons.backup),
        ),
        SwitchListTile(
          title: const Text('Cloud Sync'),
          subtitle: const Text('Sync data to cloud storage'),
          value: _cloudSync,
          onChanged: (value) => setState(() => _cloudSync = value),
          secondary: const Icon(Icons.cloud),
        ),
        ListTile(
          title: const Text('Backup Frequency'),
          subtitle: Text(_backupFrequency),
          trailing: DropdownButton<String>(
            value: _backupFrequency,
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(
                value: 'monthly',
                child: Text('Monthly'),
              ),
            ],
            onChanged:
                (value) => setState(() => _backupFrequency = value!),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Save Settings'),
          ),
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
              const Text(
                'Backup Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Last Cloud Sync',
                      value: _lastSyncTime ?? 'Never',
                      icon: Icons.cloud_sync,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Last Local Backup',
                      value: _lastBackupTime ?? 'Never',
                      icon: Icons.backup,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBackupActions(),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backup Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Auto Backup'),
                        subtitle: const Text('Automatically backup data'),
                        value: _autoBackup,
                        onChanged: (value) => setState(() => _autoBackup = value),
                        secondary: const Icon(Icons.backup),
                      ),
                      SwitchListTile(
                        title: const Text('Cloud Sync'),
                        subtitle: const Text('Sync data to cloud storage'),
                        value: _cloudSync,
                        onChanged: (value) => setState(() => _cloudSync = value),
                        secondary: const Icon(Icons.cloud),
                      ),
                      ListTile(
                        title: const Text('Backup Frequency'),
                        subtitle: Text(_backupFrequency),
                        trailing: DropdownButton<String>(
                          value: _backupFrequency,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (value) => setState(() => _backupFrequency = value!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRestoreSection(),
                    ],
                  ),
                ),
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Backup Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Last Cloud Sync',
                      value: _lastSyncTime ?? 'Never',
                      icon: Icons.cloud_sync,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Last Local Backup',
                      value: _lastBackupTime ?? 'Never',
                      icon: Icons.backup,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBackupActions(),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backup Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Auto Backup'),
                        subtitle: const Text('Automatically backup data'),
                        value: _autoBackup,
                        onChanged: (value) => setState(() => _autoBackup = value),
                        secondary: const Icon(Icons.backup),
                      ),
                      SwitchListTile(
                        title: const Text('Cloud Sync'),
                        subtitle: const Text('Sync data to cloud storage'),
                        value: _cloudSync,
                        onChanged: (value) => setState(() => _cloudSync = value),
                        secondary: const Icon(Icons.cloud),
                      ),
                      ListTile(
                        title: const Text('Backup Frequency'),
                        subtitle: Text(_backupFrequency),
                        trailing: DropdownButton<String>(
                          value: _backupFrequency,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (value) => setState(() => _backupFrequency = value!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRestoreSection(),
                    ],
                  ),
                ),
              ),
            ],
          );

    if (isWindows(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Data & Backup'),
          backgroundColor: Colors.green.shade700,
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
                          const Icon(
                            Icons.backup,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Data & Backup',
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
          title: const Text('Data & Backup'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
  }
}
