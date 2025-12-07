import 'package:freezed_annotation/freezed_annotation.dart';

part 'isolate_config.freezed.dart';

/// Configuration snapshot for server isolate startup.
///
/// Contains all settings needed by the server isolate to operate
/// independently without round-trips to the main isolate.
@freezed
class IsolateConfig with _$IsolateConfig {
  /// Creates a new [IsolateConfig] instance.
  const factory IsolateConfig({
    /// Port number for HTTP server binding (typically 53318).
    required int port,

    /// Directory path for saving received files.
    required String destinationPath,

    /// If true, auto-accept transfers without prompting user.
    required bool quickSaveEnabled,
  }) = _IsolateConfig;

  const IsolateConfig._();

  /// Converts to isolate-safe Map for transmission via SendPort.
  Map<String, dynamic> toMap() => {
        'port': port,
        'destinationPath': destinationPath,
        'quickSaveEnabled': quickSaveEnabled,
      };

  /// Creates from isolate-received Map.
  static IsolateConfig fromMap(Map<String, dynamic> map) => IsolateConfig(
        port: map['port'] as int,
        destinationPath: map['destinationPath'] as String,
        quickSaveEnabled: map['quickSaveEnabled'] as bool,
      );
}

