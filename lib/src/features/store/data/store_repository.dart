import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.description,
    required this.address,
    required this.logoPath,
  });

  final String name;
  final String description;
  final String address;
  final String? logoPath;

  StoreInfo copyWith({
    String? name,
    String? description,
    String? address,
    String? logoPath,
    bool clearLogoPath = false,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
    );
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(AppDatabase.instance);
});

final storeInfoProvider = FutureProvider<StoreInfo>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.getStore();
});

class StorePhone {
  const StorePhone({
    required this.id,
    required this.phone,
  });

  final int id;
  final String phone;
}

final storePhonesProvider = FutureProvider<List<StorePhone>>((ref) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.listPhones();
});

class StoreRepository {
  StoreRepository(this._db);

  final AppDatabase _db;

  Future<StoreInfo> getStore() async {
    final db = await _db.database;
    final row =
        (await db.query(DbTables.store, where: 'id = ?', whereArgs: [1])).single;
    return StoreInfo(
      name: (row['name'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      address: (row['address'] as String?) ?? '',
      logoPath: row['logo_path'] as String?,
    );
  }

  Future<void> updateStore(StoreInfo store) async {
    final db = await _db.database;
    await db.update(
      DbTables.store,
      {
        'name': store.name,
        'description': store.description,
        'address': store.address,
        'logo_path': store.logoPath,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<List<StorePhone>> listPhones() async {
    final db = await _db.database;
    final rows = await db.query(
      DbTables.storePhones,
      where: 'store_id = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    return rows
        .map(
          (r) => StorePhone(
            id: r['id'] as int,
            phone: (r['phone'] as String?) ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<int> addPhone(String phone) async {
    final db = await _db.database;
    return db.insert(DbTables.storePhones, {
      'store_id': 1,
      'phone': phone,
    });
  }

  Future<void> updatePhone({required int id, required String phone}) async {
    final db = await _db.database;
    await db.update(
      DbTables.storePhones,
      {'phone': phone},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePhone(int id) async {
    final db = await _db.database;
    await db.delete(
      DbTables.storePhones,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

