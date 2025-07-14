import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class DBHelper {
  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'kantemba.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE businesses(id TEXT PRIMARY KEY, name TEXT, country TEXT, businessContact TEXT, adminName TEXT, adminContact TEXT, isPremium INTEGER DEFAULT 0, subscriptionType TEXT, subscriptionStartDate TEXT, subscriptionExpiryDate TEXT, trialUsed INTEGER, lastPaymentTxRef TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE users(id TEXT PRIMARY KEY, name TEXT, contact TEXT, password TEXT, role TEXT, permissions TEXT, businessId TEXT, shopId TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE shops(id TEXT PRIMARY KEY, name TEXT, businessId TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE inventories(id TEXT PRIMARY KEY, name TEXT, price REAL, quantity INTEGER, lowStockThreshold INTEGER, createdBy TEXT, shopId TEXT, damagedRecords TEXT DEFAULT "[]", synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE expenses(id TEXT PRIMARY KEY, description TEXT, amount REAL, date TEXT, category TEXT, createdBy TEXT, shopId TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE sales(id TEXT PRIMARY KEY, totalAmount REAL, grandTotal REAL, vat REAL, turnoverTax REAL, levy REAL, date TEXT, createdBy TEXT, shopId TEXT, customerName TEXT, customerPhone TEXT, discount REAL DEFAULT 0, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, saleId TEXT, productId TEXT, productName TEXT, price REAL, quantity INTEGER, returnedQuantity INTEGER DEFAULT 0, returnedReason TEXT DEFAULT "", shopId TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE returns(id TEXT PRIMARY KEY, originalSaleId TEXT, totalReturnAmount REAL, grandReturnAmount REAL, vat REAL, turnoverTax REAL, levy REAL, date TEXT, shopId TEXT, businessId TEXT, createdBy TEXT, reason TEXT, status TEXT, approvedBy TEXT, rejectedBy TEXT, rejectionReason TEXT, approvedAt TEXT, rejectedAt TEXT, synced INTEGER DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE return_items(id INTEGER PRIMARY KEY AUTOINCREMENT, returnId TEXT, productId TEXT, productName TEXT, quantity INTEGER, originalPrice REAL, reason TEXT, shopId TEXT, synced INTEGER DEFAULT 0)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // Add returnedQuantity and returnedReason columns to sale_items table
          await db.execute('ALTER TABLE sale_items ADD COLUMN returnedQuantity INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE sale_items ADD COLUMN returnedReason TEXT DEFAULT ""');
        }
      },
      version: 4,
    );
  }

  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedData(
    String table,
  ) async {
    final db = await DBHelper.database();
    return db.query(table, where: 'synced = 0');
  }

  static Future<void> markAsSynced(String table, String id) async {
    final db = await DBHelper.database();
    await db.update(table, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>> exportAllData() async {
    final db = await DBHelper.database();
    final tables = [
      'businesses',
      'users',
      'shops',
      'inventories',
      'expenses',
      'sales',
      'sale_items',
      'returns',
      'return_items',
    ];
    final Map<String, dynamic> exportData = {};
    for (final table in tables) {
      exportData[table] = await db.query(table);
    }
    return exportData;
  }

  static Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    final batch = db.batch();
    final tables = [
      'businesses',
      'users',
      'shops',
      'inventories',
      'expenses',
      'sales',
      'sale_items',
      'returns',
      'return_items',
    ];
    for (final table in tables) {
      batch.delete(table);
      for (final row in (data[table] ?? [])) {
        batch.insert(
          table,
          Map<String, Object>.from(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  static Future<Map<String, dynamic>?> getDataById(
    String table,
    String id,
  ) async {
    final db = await DBHelper.database();
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getDataByBusinessId(
    String table,
    String businessId,
  ) async {
    final db = await DBHelper.database();
    return db.query(table, where: 'businessId = ?', whereArgs: [businessId]);
  }

  static Future<void> update(
    String table,
    Map<String, Object> data,
    String id,
  ) async {
    final db = await DBHelper.database();
    db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(String table, String id) async {
    final db = await DBHelper.database();
    db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> hasUnsyncedData() async {
    final db = await DBHelper.database();
    final tables = [
      'businesses',
      'users',
      'shops',
      'inventories',
      'expenses',
      'sales',
      'sale_items',
      'returns',
      'return_items',
    ];
    for (final table in tables) {
      final result = await db.query(table, where: 'synced = 0', limit: 1);
      if (result.isNotEmpty) return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> getAllUnsyncedData() async {
    final db = await DBHelper.database();
    final tables = [
      'businesses',
      'users',
      'shops',
      'inventories',
      'expenses',
      'sales',
      'sale_items',
      'returns',
      'return_items',
    ];
    final Map<String, dynamic> unsyncedData = {};
    for (final table in tables) {
      unsyncedData[table] = await db.query(table, where: 'synced = 0');
    }
    return unsyncedData;
  }
}
