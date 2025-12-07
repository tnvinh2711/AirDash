/// Contract: IsolateCommand
///
/// Commands sent from main isolate to server isolate.
/// This is a Freezed sealed class specification.
///
/// Feature: 009-server-background-isolate
/// Date: 2025-12-07

// Expected implementation in: lib/src/features/receive/domain/isolate_command.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'isolate_command.freezed.dart';

/// Configuration snapshot for server isolate startup.
@freezed
class IsolateConfig with _$IsolateConfig {
  const factory IsolateConfig({
    /// Port number for HTTP server binding (typically 53318).
    required int port,

    /// Directory path for saving received files.
    required String destinationPath,

    /// If true, auto-accept transfers without prompting user.
    required bool quickSaveEnabled,
  }) = _IsolateConfig;

  /// Converts to isolate-safe Map for transmission.
  Map<String, dynamic> toMap() => {
        'port': port,
        'destinationPath': destinationPath,
        'quickSaveEnabled': quickSaveEnabled,
      };

  /// Creates from isolate-received Map.
  factory IsolateConfig.fromMap(Map<String, dynamic> map) => IsolateConfig(
        port: map['port'] as int,
        destinationPath: map['destinationPath'] as String,
        quickSaveEnabled: map['quickSaveEnabled'] as bool,
      );
}

/// Commands sent from main isolate to server isolate.
@freezed
sealed class IsolateCommand with _$IsolateCommand {
  /// Start the HTTP server with the given configuration.
  const factory IsolateCommand.startServer({
    required IsolateConfig config,
  }) = StartServerCommand;

  /// Gracefully stop the HTTP server.
  const factory IsolateCommand.stopServer() = StopServerCommand;

  /// User's accept/reject decision for a pending handshake request.
  const factory IsolateCommand.respondHandshake({
    /// The requestId from IncomingRequestEvent to correlate.
    required String requestId,

    /// True if user accepted, false if rejected.
    required bool accepted,
  }) = RespondHandshakeCommand;

  /// Converts to isolate-safe Map for transmission via SendPort.
  Map<String, dynamic> toMap() => switch (this) {
        StartServerCommand(:final config) => {
            'type': 'startServer',
            'config': config.toMap(),
          },
        StopServerCommand() => {'type': 'stopServer'},
        RespondHandshakeCommand(:final requestId, :final accepted) => {
            'type': 'respondHandshake',
            'requestId': requestId,
            'accepted': accepted,
          },
      };

  /// Creates from isolate-received Map.
  static IsolateCommand fromMap(Map<String, dynamic> map) {
    return switch (map['type'] as String) {
      'startServer' => IsolateCommand.startServer(
          config: IsolateConfig.fromMap(map['config'] as Map<String, dynamic>),
        ),
      'stopServer' => const IsolateCommand.stopServer(),
      'respondHandshake' => IsolateCommand.respondHandshake(
          requestId: map['requestId'] as String,
          accepted: map['accepted'] as bool,
        ),
      _ => throw ArgumentError('Unknown command type: ${map['type']}'),
    };
  }
}

