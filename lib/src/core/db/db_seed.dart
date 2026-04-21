import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'tables.dart';

/// Lightweight seeding for local-only demo data.
///
/// This is idempotent: it only inserts data if the tables are empty.
class DbSeed {
  static Future<void> seedIfEmpty(Database db) async {
    final itemsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.items}'),
    );
    if ((itemsCount ?? 0) == 0) {
      await _seedItems(db);
    }

    final invoicesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DbTables.invoices}'),
    );
    if ((invoicesCount ?? 0) == 0) {
      await _seedInvoice(db);
    }
  }

  static Future<void> _seedItems(Database db) async {
    final demo = <Map<String, Object?>>[
      {'name': 'Milk 1L', 'price_cents': 250},
      {'name': 'Bread', 'price_cents': 180},
      {'name': 'Eggs (12)', 'price_cents': 420},
      {'name': 'Coffee 250g', 'price_cents': 799},
    ];
    for (final row in demo) {
      await db.insert(DbTables.items, row);
    }
  }

  static Future<void> _seedInvoice(Database db) async {
    final storeRow = (await db.query(DbTables.store, where: 'id = ?', whereArgs: [1])).single;
    final phones = await db.query(DbTables.storePhones, where: 'store_id = ?', whereArgs: [1]);
    final phonesJson = jsonEncode(phones.map((e) => e['phone']).toList());

    final invoiceId = await db.insert(DbTables.invoices, {
      'name': 'Demo Invoice',
      'description': 'Example invoice generated as dummy data.',
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      'store_name': storeRow['name'],
      'store_description': storeRow['description'],
      'store_logo_path': storeRow['logo_path'],
      'store_phones_json': phonesJson,
    });

    final items = await db.query(DbTables.items, limit: 3);
    if (items.isEmpty) return;
    await db.insert(DbTables.invoiceItems, {
      'invoice_id': invoiceId,
      'item_id': items[0]['id'],
      'item_name': items[0]['name'],
      'quantity': 2,
      'price_cents': items[0]['price_cents'],
    });
    await db.insert(DbTables.invoiceItems, {
      'invoice_id': invoiceId,
      'item_id': items[1]['id'],
      'item_name': items[1]['name'],
      'quantity': 1,
      'price_cents': items[1]['price_cents'],
    });
  }
}

