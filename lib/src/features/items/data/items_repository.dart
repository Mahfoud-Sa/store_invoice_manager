import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.priceCents,
  });

  final int id;
  final String name;
  final int priceCents;
}

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository(AppDatabase.instance);
});

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final repo = ref.watch(itemsRepositoryProvider);
  return repo.listItems();
});

class ItemsRepository {
  ItemsRepository(this._db);

  final AppDatabase _db;

  Future<List<Item>> listItems() async {
    final db = await _db.database;
    final rows = await db.query(
      DbTables.items,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows
        .map(
          (r) => Item(
            id: r['id'] as int,
            name: (r['name'] as String?) ?? '',
            priceCents: (r['price_cents'] as int?) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<int> createItem({required String name, required int priceCents}) async {
    final db = await _db.database;
    return db.insert(DbTables.items, {
      'name': name,
      'price_cents': priceCents,
    });
  }

  Future<void> updateItem({
    required int id,
    required String name,
    required int priceCents,
  }) async {
    final db = await _db.database;
    await db.update(
      DbTables.items,
      {
        'name': name,
        'price_cents': priceCents,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await _db.database;
    await db.delete(
      DbTables.items,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

