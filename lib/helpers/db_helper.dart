import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';

class DBHelper {
  static Future<Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(path.join(dbPath, 'kantemba.db'),
        onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE users(id TEXT PRIMARY KEY, name TEXT, password TEXT, role TEXT, permissions TEXT)',
      );
      await db.execute(
        'CREATE TABLE business(id TEXT PRIMARY KEY, name TEXT, isMultiShop INTEGER, isVatRegistered INTEGER, isTurnoverTaxApplicable INTEGER)',
      );
      await db.execute(
        'CREATE TABLE inventory(id TEXT PRIMARY KEY, name TEXT, price REAL, quantity INTEGER, lowStockThreshold INTEGER, createdBy TEXT)',
      );
      await db.execute(
        'CREATE TABLE expenses(id TEXT PRIMARY KEY, description TEXT, amount REAL, date TEXT, category TEXT, createdBy TEXT)',
      );
      await db.execute(
        'CREATE TABLE sales(id TEXT PRIMARY KEY, totalAmount REAL, grandTotal REAL, vat REAL, turnoverTax REAL, levy REAL, date TEXT, createdBy TEXT)',
      );
      await db.execute(
        'CREATE TABLE sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, saleId TEXT, productId TEXT, productName TEXT, price REAL, quantity INTEGER)',
      );
    }, version: 1);
  }

  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table);
  }
  
  static Future<void> update(String table, Map<String, Object> data, String id) async {
    final db = await DBHelper.database();
    db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(String table, String id) async {
    final db = await DBHelper.database();
    db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
} 