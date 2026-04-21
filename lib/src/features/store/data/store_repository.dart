import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.description,
    required this.logoPath,
  });

  final String name;
  final String description;
  final String? logoPath;

  StoreInfo copyWith({
    String? name,
    String? description,
    String? logoPath,
    bool clearLogoPath = false,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      description: description ?? this.description,
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
        'logo_path': store.logoPath,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}

