import 'dart:async';

import 'package:flux/src/features/receive/domain/receive_settings.dart';
import 'package:flux/src/features/settings/application/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receive_settings_provider.g.dart';

/// Manages Quick Save settings with persistence.
///
/// Loads saved state on initialization and persists changes to database.
/// Note: Receive Mode is always ON (auto-started), so only Quick Save
/// is configurable.
@riverpod
class ReceiveSettingsNotifier extends _$ReceiveSettingsNotifier {
  @override
  Future<ReceiveSettings> build() async {
    // Load persisted settings on startup
    final repository = ref.watch(settingsRepositoryProvider);
    final quickSaveEnabled = await repository.getQuickSave();

    return ReceiveSettings(quickSaveEnabled: quickSaveEnabled);
  }

  /// Sets Quick Save enabled state and persists to database.
  ///
  /// Updates UI state immediately (optimistic update) then persists
  /// in background.
  Future<void> setQuickSave({required bool enabled}) async {
    // Update UI state immediately for responsive feel
    final current = state.valueOrNull ?? ReceiveSettings.defaults();
    state = AsyncData(current.copyWith(quickSaveEnabled: enabled));

    // Persist to database in background (fire-and-forget)
    final repository = ref.read(settingsRepositoryProvider);
    unawaited(repository.setQuickSave(enabled: enabled));
  }

  /// Toggles Quick Save and persists to database.
  Future<void> toggleQuickSave() async {
    final current = state.valueOrNull ?? ReceiveSettings.defaults();
    await setQuickSave(enabled: !current.quickSaveEnabled);
  }
}
