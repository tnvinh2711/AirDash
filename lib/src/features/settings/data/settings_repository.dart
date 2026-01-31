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

  // ============================================================
  // Receive Mode Settings
  // ============================================================

  /// Gets whether Receive Mode is enabled.
  ///
  /// Returns `false` if not set (default for fresh install).
  Future<bool> getReceiveMode() async {
    final value = await getSetting(SettingKeys.receiveMode);
    return value == 'true';
  }

  /// Sets whether Receive Mode is enabled.
  Future<void> setReceiveMode({required bool enabled}) =>
      setSetting(SettingKeys.receiveMode, enabled.toString());

  // ============================================================
  // Quick Save Settings
  // ============================================================

  /// Gets whether Quick Save is enabled.
  ///
  /// Returns `false` if not set (default for fresh install).
  Future<bool> getQuickSave() async {
    final value = await getSetting(SettingKeys.quickSave);
    return value == 'true';
  }

  /// Sets whether Quick Save is enabled.
  Future<void> setQuickSave({required bool enabled}) =>
      setSetting(SettingKeys.quickSave, enabled.toString());

  // ============================================================
  // Selection Queue Persistence
  // ============================================================

  /// Gets the persisted selection queue as a JSON string.
  ///
  /// Returns `null` if no queue is persisted.
  Future<String?> getSelectionQueue() =>
      getSetting(SettingKeys.selectionQueue);

  /// Sets the selection queue as a JSON string.
  ///
  /// [jsonString] should be a JSON-encoded array of SelectedItem objects.
  Future<void> setSelectionQueue(String jsonString) =>
      setSetting(SettingKeys.selectionQueue, jsonString);

  /// Clears the persisted selection queue.
  Future<void> clearSelectionQueue() async {
    // Delete by setting to empty string (or we could add a delete method)
    await setSetting(SettingKeys.selectionQueue, '[]');
  }

  // ============================================================
  // Color Scheme Settings
  // ============================================================

  /// Gets the selected color scheme.
  ///
  /// Returns `null` if not set (use default scheme).
  Future<String?> getColorScheme() => getSetting(SettingKeys.colorScheme);

  /// Sets the color scheme.
  ///
  /// [scheme] should be a valid FlexScheme name.
  Future<void> setColorScheme(String scheme) =>
      setSetting(SettingKeys.colorScheme, scheme);

  // ============================================================
  // Download Path Settings
  // ============================================================

  /// Gets the custom download path.
  ///
  /// Returns `null` if not set (use default Downloads folder).
  Future<String?> getDownloadPath() => getSetting(SettingKeys.downloadPath);

  /// Sets the custom download path.
  Future<void> setDownloadPath(String path) =>
      setSetting(SettingKeys.downloadPath, path);
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

  /// Receive mode enabled key.
  static const String receiveMode = 'receive_mode';

  /// Quick save enabled key.
  static const String quickSave = 'quick_save';

  /// Selection queue persistence key (JSON array).
  static const String selectionQueue = 'selection_queue';

  /// Color scheme key.
  static const String colorScheme = 'color_scheme';

  /// Download path key.
  static const String downloadPath = 'download_path';
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
