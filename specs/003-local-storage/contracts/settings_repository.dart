// Settings Repository Contract
// Feature: 003-local-storage
//
// This file defines the interface contract for the SettingsRepository.
// Implementation will be in lib/src/features/settings/data/settings_repository.dart

/// Repository for managing user settings persistence.
///
/// Settings are stored as key-value pairs where both key and value are strings.
/// The repository provides type-safe accessors for known settings
/// (theme, alias, port) while allowing generic get/set for extensibility.
abstract interface class ISettingsRepository {
  // ============================================================
  // Generic Key-Value Operations
  // ============================================================

  /// Retrieves a setting value by key.
  ///
  /// Returns `null` if the key does not exist.
  ///
  /// Example:
  /// ```dart
  /// final theme = await repository.getSetting('theme');
  /// ```
  Future<String?> getSetting(String key);

  /// Stores or updates a setting value.
  ///
  /// If the key already exists, the value is replaced.
  /// If the key does not exist, a new entry is created.
  ///
  /// Example:
  /// ```dart
  /// await repository.setSetting('theme', 'dark');
  /// ```
  Future<void> setSetting(String key, String value);

  // ============================================================
  // Type-Safe Setting Accessors
  // ============================================================

  /// Gets the user's theme preference.
  ///
  /// Returns one of: "system", "light", "dark"
  /// Returns `null` if not set (use system default).
  Future<String?> getTheme();

  /// Sets the user's theme preference.
  ///
  /// [theme] must be one of: "system", "light", "dark"
  Future<void> setTheme(String theme);

  /// Gets the device alias for display during transfers.
  ///
  /// Returns `null` if not set (use device hostname).
  Future<String?> getAlias();

  /// Sets the device alias.
  ///
  /// [alias] should be a user-friendly device name.
  Future<void> setAlias(String alias);

  /// Gets the network port for the transfer server.
  ///
  /// Returns `null` if not set (use application default).
  Future<int?> getPort();

  /// Sets the network port for the transfer server.
  ///
  /// [port] must be a valid port number (1-65535).
  Future<void> setPort(int port);
}

// ============================================================
// Setting Keys (Constants)
// ============================================================

/// Canonical setting key constants to prevent typos.
abstract final class SettingKeys {
  static const String theme = 'theme';
  static const String alias = 'alias';
  static const String port = 'port';
}

// ============================================================
// Theme Values (Constants)
// ============================================================

/// Valid theme preference values.
abstract final class ThemeValues {
  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';
}
