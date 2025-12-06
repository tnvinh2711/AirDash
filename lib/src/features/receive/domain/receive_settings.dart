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
    @Default(false) bool quickSaveEnabled,
  }) = _ReceiveSettings;

  /// Default settings for fresh install.
  factory ReceiveSettings.defaults() => const ReceiveSettings();
}


