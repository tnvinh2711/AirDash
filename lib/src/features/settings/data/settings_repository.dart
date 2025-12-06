import 'package:flux/src/core/database/app_database.dart';

/// Repository for managing user settings persistence.
///
/// Settings are stored as key-value pairs where both key and value are strings.
/// The repository provides type-safe accessors for known settings
/// (theme, alias, port) while allowing generic get/set for extensibility.
class SettingsRepository {
  /// Creates a [SettingsRepository] with the given [AppDatabase].
  SettingsRepository(this._db);

  final AppDatabase _db;

  // ============================================================
  // Generic Key-Value Operations
  // ============================================================

  /// Retrieves a setting value by key.
  ///
  /// Returns `null` if the key does not exist.
  Future<String?> getSetting(String key) async {
    final query = _db.select(_db.settingsTable)
      ..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// Stores or updates a setting value.
  ///
  /// If the key already exists, the value is replaced.
  /// If the key does not exist, a new entry is created.
  Future<void> setSetting(String key, String value) async {
    await _db
        .into(_db.settingsTable)
        .insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: key, value: value),
        );
  }

  // ============================================================
  // Type-Safe Setting Accessors
  // ============================================================

  /// Gets the user's theme preference.
  ///
  /// Returns one of: "system", "light", "dark"
  /// Returns `null` if not set (use system default).
  Future<String?> getTheme() => getSetting(SettingKeys.theme);

  /// Sets the user's theme preference.
  ///
  /// [theme] must be one of: "system", "light", "dark"
  Future<void> setTheme(String theme) => setSetting(SettingKeys.theme, theme);

  /// Gets the device alias for display during transfers.
  ///
  /// Returns `null` if not set (use device hostname).
  Future<String?> getAlias() => getSetting(SettingKeys.alias);

  /// Sets the device alias.
  ///
  /// [alias] should be a user-friendly device name.
  Future<void> setAlias(String alias) => setSetting(SettingKeys.alias, alias);

  /// Gets the network port for the transfer server.
  ///
  /// Returns `null` if not set (use application default).
  Future<int?> getPort() async {
    final value = await getSetting(SettingKeys.port);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Sets the network port for the transfer server.
  ///
  /// [port] must be a valid port number (1-65535).
  Future<void> setPort(int port) =>
      setSetting(SettingKeys.port, port.toString());
}

// ============================================================
// Setting Keys (Constants)
// ============================================================

/// Canonical setting key constants to prevent typos.
abstract final class SettingKeys {
  /// Theme preference key.
  static const String theme = 'theme';

  /// Device alias key.
  static const String alias = 'alias';

  /// Network port key.
  static const String port = 'port';
}

// ============================================================
// Theme Values (Constants)
// ============================================================

/// Valid theme preference values.
abstract final class ThemeValues {
  /// Use system theme.
  static const String system = 'system';

  /// Use light theme.
  static const String light = 'light';

  /// Use dark theme.
  static const String dark = 'dark';
}
