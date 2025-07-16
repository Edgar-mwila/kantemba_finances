import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/helpers/api_service.dart';

class SyncManager {
  static Future<bool> batchSyncAndMarkSynced() async {
    final unsyncedData = await DBHelper.getAllUnsyncedData();

    // 1. Fetch business object
    final business = await DBHelper.getBusiness(); // Implement this in DBHelper if not present

    // 2. Ensure sales are present before sale_items
    final salesList = List<Map<String, dynamic>>.from(unsyncedData['sales'] ?? []);
    final saleItemsList = List<Map<String, dynamic>>.from(unsyncedData['sale_items'] ?? []);

    // 3. Filter sale_items to only those with a valid saleId
    final validSaleIds = salesList.map((s) => s['id']).toSet();
    final filteredSaleItems = saleItemsList.where((item) {
      final isValid = validSaleIds.contains(item['saleId']);
      if (!isValid) {
        print('[SyncManager] Warning: Skipping orphaned sale_item with saleId: \'${item['saleId']}\'');
      }
      return isValid;
    }).toList();

    // 4. Build the payload with business, sales, and filtered sale_items
    final payload = {
      'business': business,
      ...unsyncedData,
      'sales': salesList,
      'sale_items': filteredSaleItems,
    };

    if (payload.values.every((list) => list is List ? list.isEmpty : list == null)) return true; // Nothing to sync
    final success = await ApiService.batchSync(payload);
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