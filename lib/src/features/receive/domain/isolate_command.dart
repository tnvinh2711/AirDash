import 'package:flux/src/features/receive/domain/isolate_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'isolate_command.freezed.dart';

/// Commands sent from main isolate to server isolate.
///
/// These commands control the server lifecycle and respond to
/// user decisions on incoming transfer requests.
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

  const IsolateCommand._();

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

