import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Application settings model.
///
/// Contains all user-configurable settings for the app.
@freezed
class AppSettings with _$AppSettings {
  /// Creates an [AppSettings] instance.
  const factory AppSettings({
    /// Theme mode (light, dark, or system).
    required ThemeMode themeMode,

    /// Color scheme for the app.
    required FlexScheme colorScheme,

    /// Custom device alias (null = use device hostname).
    String? deviceAlias,

    /// Custom network port (null = use default 8080).
    int? port,

    /// Custom download path (null = use default Downloads folder).
    String? downloadPath,
  }) = _AppSettings;

  /// Creates an [AppSettings] from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

