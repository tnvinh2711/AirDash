import 'package:drift/drift.dart';

/// Drift table definition for user settings.
///
/// Stores key-value pairs for user preferences like theme, alias, and port.
@DataClassName('SettingEntry')
class SettingsTable extends Table {
  /// Unique setting identifier (e.g., "theme", "alias", "port").
  TextColumn get key => text()();

  /// Serialized setting value.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
