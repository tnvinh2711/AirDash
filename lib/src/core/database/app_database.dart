import 'package:drift/drift.dart';
import 'package:flux/src/core/database/tables/settings_table.dart';
import 'package:flux/src/core/database/tables/transfer_history_table.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';

part 'app_database.g.dart';

/// Main application database using Drift.
///
/// Contains tables for:
/// - [SettingsTable]: User preferences (theme, alias, port)
/// - [TransferHistoryTable]: Transfer history records
@DriftDatabase(tables: [SettingsTable, TransferHistoryTable])
class AppDatabase extends _$AppDatabase {
  /// Creates an [AppDatabase] with the given [QueryExecutor].
  ///
  /// Use [connection] from `connection.dart` for production,
  /// or `NativeDatabase.memory()` for testing.
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be handled here
      },
    );
  }
}
