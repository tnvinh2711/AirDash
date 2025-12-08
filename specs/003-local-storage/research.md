# Research: Local Storage with Drift

**Feature**: 003-local-storage | **Date**: 2025-12-05

## Research Tasks

### 1. Drift Database Setup for Flutter

**Decision**: Use `drift` with `sqlite3_flutter_libs` for cross-platform SQLite support

**Rationale**:
- Drift is the constitution-mandated local database solution
- `sqlite3_flutter_libs` provides native SQLite binaries for all Flutter platforms
- Type-safe queries with compile-time checking
- Built-in migration support for schema changes

**Alternatives Considered**:
- `sqflite`: Less type-safe, older API, no code generation
- `hive`: NoSQL approach, less suitable for relational history data
- `shared_preferences`: Only suitable for simple key-value, no query capabilities

### 2. Drift Table Definition Patterns

**Decision**: Define tables using Drift's annotation-based syntax with `@DataClassName`

**Rationale**:
- Cleaner separation between table schema and generated data classes
- Allows custom data class names (e.g., `TransferHistoryEntry` instead of `TransferHistoryTableData`)
- Supports enum converters for `status` and `direction` fields

**Key Patterns**:
```dart
// Table definition with custom data class name
@DataClassName('Setting')
class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  
  @override
  Set<Column> get primaryKey => {key};
}

// Enum converter for type-safe enums
class TransferStatusConverter extends TypeConverter<TransferStatus, String> {
  const TransferStatusConverter();
  
  @override
  TransferStatus fromSql(String fromDb) => TransferStatus.values.byName(fromDb);
  
  @override
  String toSql(TransferStatus value) => value.name;
}
```

### 3. Stream-based Queries for Live Updates

**Decision**: Use Drift's `watch` methods for reactive streams

**Rationale**:
- Drift provides built-in `watchAll()`, `watchSingle()` methods
- Streams automatically emit new values on database changes
- Integrates cleanly with Riverpod's `StreamProvider`
- No manual refresh logic needed

**Pattern**:
```dart
// Repository method returning Stream
Stream<List<TransferHistoryEntry>> watchAllHistory() {
  return (select(transferHistoryTable)
    ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
    .watch();
}
```

### 4. In-Memory Database for Testing

**Decision**: Use `NativeDatabase.memory()` for unit tests

**Rationale**:
- Fast test execution (no disk I/O)
- Clean isolation between test cases
- Same API as production database
- Supports schema verification in tests

**Pattern**:
```dart
// Test setup
late AppDatabase database;

setUp(() {
  database = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  await database.close();
});
```

### 5. Database Migration Strategy

**Decision**: Use Drift's `schemaVersion` with `migration` callback

**Rationale**:
- Drift tracks schema version automatically
- Migration callbacks allow incremental updates
- Can handle both destructive and non-destructive migrations

**Pattern**:
```dart
@DriftDatabase(tables: [SettingsTable, TransferHistoryTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Future migrations go here
    },
  );
}
```

### 6. Repository Pattern with Riverpod

**Decision**: Repositories as plain classes provided via Riverpod `Provider`

**Rationale**:
- Constitution allows direct repository usage (no abstract interfaces needed)
- Repositories encapsulate Drift query logic
- Single database instance shared via provider

**Pattern**:
```dart
// Database provider (singleton)
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
}

// Repository provider
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}
```

### 7. Platform-Specific Database Path

**Decision**: Use `path_provider` with platform-specific directories

**Rationale**:
- `getApplicationDocumentsDirectory()` works on all platforms
- Database file persists across app restarts
- Follows platform conventions for data storage

**Implementation**:
```dart
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'flux.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

## Dependencies to Add

```yaml
dependencies:
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.22.0
```

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| How to handle database corruption? | Drift auto-creates fresh DB if file missing/corrupt |
| How to ensure thread safety? | `NativeDatabase.createInBackground` runs on isolate |
| How to handle large history lists? | Drift streams are lazy; use pagination if needed |

