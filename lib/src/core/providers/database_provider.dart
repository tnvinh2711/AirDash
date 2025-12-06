import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/database/app_database.dart';
import 'package:flux/src/core/database/connection/connection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// Provides the singleton [AppDatabase] instance.
///
/// The database is lazily initialized on first access and persists
/// for the lifetime of the application.
///
/// Usage:
/// ```dart
/// final db = ref.watch(databaseProvider);
/// ```
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase(openConnection());

  ref.onDispose(db.close);

  return db;
}
