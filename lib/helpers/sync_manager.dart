import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/helpers/api_service.dart';

class SyncManager {
  static Future<bool> batchSyncAndMarkSynced() async {
    final unsyncedData = await DBHelper.getAllUnsyncedData();
    if (unsyncedData.values.every((list) => list.isEmpty)) return true; // Nothing to sync
    final success = await ApiService.batchSync(unsyncedData);
    if (success) {
      // Mark all as synced
      for (final table in unsyncedData.keys) {
        for (final row in unsyncedData[table]) {
          await DBHelper.markAsSynced(table, row['id'].toString());
        }
      }
    }
    return success;
  }
} 