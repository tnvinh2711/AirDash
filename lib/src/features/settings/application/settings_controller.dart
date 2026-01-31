import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flux/src/features/settings/application/settings_provider.dart';
import 'package:flux/src/features/settings/data/settings_repository.dart';
import 'package:flux/src/features/settings/domain/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// Controller for managing app settings.
///
/// Loads settings from repository and provides methods to update them.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<AppSettings> build() async {
    final repository = ref.watch(settingsRepositoryProvider);

    // Load all settings
    final themeMode = await _loadThemeMode(repository);
    final colorScheme = await _loadColorScheme(repository);
    final alias = await repository.getAlias();
    final port = await repository.getPort();
    final downloadPath = await repository.getDownloadPath();

    return AppSettings(
      themeMode: themeMode,
      colorScheme: colorScheme,
      deviceAlias: alias,
      port: port,
      downloadPath: downloadPath,
    );
  }

  Future<ThemeMode> _loadThemeMode(SettingsRepository repository) async {
    final theme = await repository.getTheme();
    return switch (theme) {
      ThemeValues.light => ThemeMode.light,
      ThemeValues.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<FlexScheme> _loadColorScheme(SettingsRepository repository) async {
    final schemeName = await repository.getColorScheme();
    if (schemeName == null) return FlexScheme.barossa;

    // Try to parse the scheme name
    try {
      return FlexScheme.values.firstWhere(
        (s) => s.name == schemeName,
        orElse: () => FlexScheme.barossa,
      );
    } catch (_) {
      return FlexScheme.barossa;
    }
  }

  /// Updates the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    final repository = ref.read(settingsRepositoryProvider);
    final themeValue = switch (mode) {
      ThemeMode.light => ThemeValues.light,
      ThemeMode.dark => ThemeValues.dark,
      ThemeMode.system => ThemeValues.system,
    };

    await repository.setTheme(themeValue);
    ref.invalidateSelf();
  }

  /// Updates the color scheme.
  Future<void> setColorScheme(FlexScheme scheme) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setColorScheme(scheme.name);
    ref.invalidateSelf();
  }

  /// Updates the device alias.
  Future<void> setDeviceAlias(String alias) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setAlias(alias);
    ref.invalidateSelf();
  }

  /// Updates the network port.
  Future<void> setPort(int port) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setPort(port);
    ref.invalidateSelf();
  }

  /// Updates the download path.
  Future<void> setDownloadPath(String path) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setDownloadPath(path);
    ref.invalidateSelf();
  }

  /// Clears the download path (use default).
  Future<void> clearDownloadPath() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setSetting(SettingKeys.downloadPath, '');
    ref.invalidateSelf();
  }
}

