# Quickstart: Local Storage Implementation

**Feature**: 003-local-storage | **Date**: 2025-12-05

## Prerequisites

- Flutter SDK via FVM (stable channel)
- Existing project setup with `flutter_riverpod`, `freezed`

## 1. Add Dependencies

```bash
# Add runtime dependencies
flutter pub add drift sqlite3_flutter_libs path_provider path

# Add dev dependencies
flutter pub add --dev drift_dev
```

## 2. Create Database Tables

Create `lib/src/core/database/tables/settings_table.dart`:
```dart
import 'package:drift/drift.dart';

@DataClassName('Setting')
class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  
  @override
  Set<Column> get primaryKey => {key};
}
```

Create `lib/src/core/database/tables/transfer_history_table.dart`:
```dart
import 'package:drift/drift.dart';

@DataClassName('TransferHistoryEntry')
class TransferHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text()();
  TextColumn get fileName => text()();
  IntColumn get fileCount => integer().withDefault(const Constant(1))();
  IntColumn get totalSize => integer()();
  TextColumn get fileType => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text()(); // Uses TypeConverter
  TextColumn get direction => text()(); // Uses TypeConverter
  TextColumn get remoteDeviceAlias => text()();
}
```

## 3. Create Database Class

Create `lib/src/core/database/app_database.dart`:
```dart
import 'package:drift/drift.dart';
import 'tables/settings_table.dart';
import 'tables/transfer_history_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SettingsTable, TransferHistoryTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

## 4. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 5. Create Database Provider

Create `lib/src/core/providers/database_provider.dart`:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/app_database.dart';
import '../database/connection/connection.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
}
```

## 6. Running Tests

Use in-memory database for tests:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('should store and retrieve setting', () async {
    await db.into(db.settingsTable).insert(
      SettingsTableCompanion.insert(key: 'theme', value: 'dark'),
    );
    
    final result = await (db.select(db.settingsTable)
      ..where((t) => t.key.equals('theme'))).getSingleOrNull();
    
    expect(result?.value, 'dark');
  });
}
```

## 7. Usage Example

```dart
// In a widget or provider
final db = ref.watch(appDatabaseProvider);
final settingsRepo = SettingsRepository(db);

// Get theme
final theme = await settingsRepo.getTheme();

// Watch history (reactive)
ref.watch(historyProvider).when(
  data: (entries) => ListView(children: entries.map(...)),
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
);
```

## Platform Notes

| Platform | SQLite Provider | Notes |
|----------|-----------------|-------|
| Android | `sqlite3_flutter_libs` | Bundled SQLite |
| iOS | `sqlite3_flutter_libs` | Bundled SQLite |
| macOS | `sqlite3_flutter_libs` | Bundled SQLite |
| Windows | `sqlite3_flutter_libs` | Bundled SQLite |
| Linux | `sqlite3_flutter_libs` | Bundled SQLite |

All platforms use the same API - no platform-specific code required.

## Common Issues

1. **"Cannot find native library"**: Ensure `sqlite3_flutter_libs` is in dependencies
2. **Generated files missing**: Run `dart run build_runner build`
3. **Migration errors**: Increment `schemaVersion` and add migration logic

