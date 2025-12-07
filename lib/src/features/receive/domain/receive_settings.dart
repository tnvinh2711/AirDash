import 'package:freezed_annotation/freezed_annotation.dart';

part 'receive_settings.freezed.dart';

/// User settings for receive functionality.
///
/// Stores user preferences for the Receive tab,
/// primarily the auto-accept behavior for incoming transfers.
@freezed
class ReceiveSettings with _$ReceiveSettings {
  /// Creates a [ReceiveSettings] instance.
  const factory ReceiveSettings({
    /// Whether Quick Save is enabled (auto-accept transfers).
    ///
    /// Default is `true` because accept/reject UI is not yet implemented.
    /// TODO(receive-ui): Change default to false when accept/reject dialog is ready.
    @Default(true) bool quickSaveEnabled,
  }) = _ReceiveSettings;

  /// Default settings for fresh install.
  factory ReceiveSettings.defaults() => const ReceiveSettings();
}


