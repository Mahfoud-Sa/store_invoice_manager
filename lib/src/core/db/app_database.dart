import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../errors/app_exception.dart';
import 'db_seed.dart';
import 'tables.dart';

/// SQLite database wrapper.
///
/// - Enables foreign keys
/// - Creates all tables
/// - Provides a single shared [Database] instance
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'store_invoice_manager.db');
  }

  Future<Database> _open() async {
    try {
      final dbPath = await _dbPath();
      return await openDatabase(
        dbPath,
        version: DbSchema.version,
        onConfigure: (db) async {
          // Needed for ON DELETE/UPDATE rules & relational integrity.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createV1(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Migrations (incremental).
          if (oldVersion < 2) {
            // Add store address.
            await db.execute(
              "ALTER TABLE ${DbTables.store} ADD COLUMN address TEXT NOT NULL DEFAULT ''",
            );
          }
        },
      );
    } catch (e, st) {
      throw AppException('Failed to open local database.', cause: e, stackTrace: st);
    }
  }

  Future<void> _createV1(Database db) async {
    // Store info (single row) + phones (multiple rows).
    await db.execute('''
CREATE TABLE ${DbTables.store} (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  logo_path TEXT
)
''');

    await db.execute('''
CREATE TABLE ${DbTables.storePhones} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  store_id INTEGER NOT NULL,
  phone TEXT NOT NULL,
  FOREIGN KEY(store_id) REFERENCES ${DbTables.store}(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
)
''');

    // Reusable items.
    await db.execute('''
CREATE TABLE ${DbTables.items} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price_cents INTEGER NOT NULL
)
''');

    // Invoices keep a snapshot of store details at creation time.
    await db.execute('''
CREATE TABLE ${DbTables.invoices} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_at_ms INTEGER NOT NULL,

  store_name TEXT NOT NULL,
  store_description TEXT NOT NULL DEFAULT '',
  store_logo_path TEXT,
  store_phones_json TEXT NOT NULL DEFAULT '[]'
)
''');

    await db.execute('''
CREATE TABLE ${DbTables.invoiceItems} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  item_id INTEGER,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price_cents INTEGER NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES ${DbTables.invoices}(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY(item_id) REFERENCES ${DbTables.items}(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
)
''');

    await db.execute('CREATE INDEX idx_invoice_items_invoice_id ON ${DbTables.invoiceItems}(invoice_id)');
    await db.execute('CREATE INDEX idx_invoice_items_item_id ON ${DbTables.invoiceItems}(item_id)');

    // Ensure there is always a store row.
    await db.insert(DbTables.store, {
      'id': 1,
      'name': 'My Store',
      'description': 'Welcome! Update your store settings.',
      'address': '',
      'logo_path': null,
    });
  }

  /// Call this once at app startup to seed dummy data.
  Future<void> seedIfEmpty() async {
    final db = await database;
    await DbSeed.seedIfEmpty(db);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}

