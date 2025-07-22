import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/helpers/api_service.dart';

class SyncManager {
  static Future<bool> batchSyncAndMarkSynced() async {
    final unsyncedData = await DBHelper.getAllUnsyncedData();

    // Add receivables, payables, and loans to payload
    final unsyncedReceivables = await DBHelper.getReceivables();
    final unsyncedPayables = await DBHelper.getPayables();
    final unsyncedLoans = await DBHelper.getLoans();

    final payload = {
      ...unsyncedData,
      'receivables': unsyncedReceivables,
      'payables': unsyncedPayables,
      'loans': unsyncedLoans,
    };
    
    final success = await ApiService.batchSync(payload);
    if (success) {
      // Mark all as synced, including new types
      for (final table in [...unsyncedData.keys, 'receivables', 'payables', 'loans']) {
        final dataToMark = payload[table];
        if (dataToMark is List) {
          for (final row in dataToMark) {
            await DBHelper.markAsSynced(table, row['id'].toString());
          }
        }
      }
    }
    return success;
  }
} 