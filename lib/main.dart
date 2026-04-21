import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/core/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed demo data once (idempotent) to make the app usable immediately.
  await AppDatabase.instance.seedIfEmpty();

  runApp(
    const ProviderScope(
      child: StoreInvoiceApp(),
    ),
  );
}
