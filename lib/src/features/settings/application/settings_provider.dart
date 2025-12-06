import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/database_provider.dart';
import 'package:flux/src/features/settings/data/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

/// Provides the [SettingsRepository] instance.
///
/// The repository is lazily initialized and persists for the lifetime
/// of the application.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
}

/// Provides the current theme setting.
///
/// Returns `null` if no theme is set (use system default).
@riverpod
Future<String?> themeSetting(Ref ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getTheme();
}

/// Provides the current device alias setting.
///
/// Returns `null` if no alias is set (use device hostname).
@riverpod
Future<String?> aliasSetting(Ref ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getAlias();
}

/// Provides the current port setting.
///
/// Returns `null` if no port is set (use application default).
@riverpod
Future<int?> portSetting(Ref ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getPort();
}
