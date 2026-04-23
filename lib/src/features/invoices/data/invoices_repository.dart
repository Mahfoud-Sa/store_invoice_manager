import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

class Invoice {
  const Invoice({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAtMs,
    required this.storeName,
    required this.storeDescription,
    required this.storeLogoPath,
    required this.storePhones,
  });

  final int id;
  final String name;
  final String description;
  final int createdAtMs;
  final String storeName;
  final String storeDescription;
  final String? storeLogoPath;
  final List<String> storePhones;
}

class InvoiceLine {
  const InvoiceLine({
    required this.id,
    required this.invoiceId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.priceCents,
  });

  final int id;
  final int invoiceId;
  final int? itemId;
  final String itemName;
  final int quantity;
  final int priceCents;

  int get lineTotalCents => quantity * priceCents;
}

class InvoiceDetails {
  const InvoiceDetails({required this.invoice, required this.lines});

  final Invoice invoice;
  final List<InvoiceLine> lines;

  int get totalCents => lines.fold<int>(0, (sum, l) => sum + l.lineTotalCents);
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(AppDatabase.instance);
});

final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return repo.listInvoices();
});

final invoiceDetailsProvider = FutureProvider.family<InvoiceDetails, int>((
  ref,
  invoiceId,
) async {
  final repo = ref.watch(invoicesRepositoryProvider);
  return repo.getInvoiceDetails(invoiceId);
});

class InvoicesRepository {
  InvoicesRepository(this._db);

  final AppDatabase _db;

  Future<List<Invoice>> listInvoices() async {
    final db = await _db.database;
    final rows = await db.query(
      DbTables.invoices,
      orderBy: 'created_at_ms DESC',
    );
    return rows.map(_mapInvoiceRow).toList(growable: false);
  }

  Future<InvoiceDetails> getInvoiceDetails(int invoiceId) async {
    final db = await _db.database;
    final invoiceRow = (await db.query(
      DbTables.invoices,
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    )).single;

    final lineRows = await db.query(
      DbTables.invoiceItems,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );

    return InvoiceDetails(
      invoice: _mapInvoiceRow(invoiceRow),
      lines: lineRows.map(_mapLineRow).toList(growable: false),
    );
  }

  Future<int> createInvoice({
    required String name,
    required String description,
    required List<NewInvoiceLine> lines,
  }) async {
    final db = await _db.database;
    return db.transaction<int>((txn) async {
      final storeRow = (await txn.query(
        DbTables.store,
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      )).single;
      final phones = await txn.query(
        DbTables.storePhones,
        where: 'store_id = ?',
        whereArgs: [1],
      );
      final phonesJson = jsonEncode(phones.map((e) => e['phone']).toList());

      final invoiceId = await txn.insert(DbTables.invoices, {
        'name': name,
        'description': description,
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
        'store_name': storeRow['name'],
        'store_description': storeRow['description'],
        'store_logo_path': storeRow['logo_path'],
        'store_phones_json': phonesJson,
      });

      for (final l in lines) {
        await txn.insert(DbTables.invoiceItems, {
          'invoice_id': invoiceId,
          'item_id': l.itemId,
          'item_name': l.itemName,
          'quantity': l.quantity,
          'price_cents': l.priceCents,
        });
      }

      return invoiceId;
    });
  }

  Future<void> updateInvoice({
    required int invoiceId,
    required String name,
    required String description,
    required List<NewInvoiceLine> lines,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        DbTables.invoices,
        {'name': name, 'description': description},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Remove existing lines and re-insert
      await txn.delete(
        DbTables.invoiceItems,
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      for (final l in lines) {
        await txn.insert(DbTables.invoiceItems, {
          'invoice_id': invoiceId,
          'item_id': l.itemId,
          'item_name': l.itemName,
          'quantity': l.quantity,
          'price_cents': l.priceCents,
        });
      }
    });
  }

  Future<void> deleteInvoice(int invoiceId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        DbTables.invoiceItems,
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      await txn.delete(
        DbTables.invoices,
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  Invoice _mapInvoiceRow(Map<String, Object?> row) {
    final phonesJson = (row['store_phones_json'] as String?) ?? '[]';
    final decoded = jsonDecode(phonesJson);
    final phones = (decoded is List)
        ? decoded.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return Invoice(
      id: row['id'] as int,
      name: (row['name'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      createdAtMs: (row['created_at_ms'] as int?) ?? 0,
      storeName: (row['store_name'] as String?) ?? '',
      storeDescription: (row['store_description'] as String?) ?? '',
      storeLogoPath: row['store_logo_path'] as String?,
      storePhones: phones,
    );
  }

  InvoiceLine _mapLineRow(Map<String, Object?> row) {
    return InvoiceLine(
      id: row['id'] as int,
      invoiceId: row['invoice_id'] as int,
      itemId: row['item_id'] as int?,
      itemName: (row['item_name'] as String?) ?? '',
      quantity: (row['quantity'] as int?) ?? 0,
      priceCents: (row['price_cents'] as int?) ?? 0,
    );
  }
}

class NewInvoiceLine {
  const NewInvoiceLine({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.priceCents,
  });

  final int? itemId;
  final String itemName;
  final int quantity;
  final int priceCents;
}
