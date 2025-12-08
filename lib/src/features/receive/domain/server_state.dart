import 'package:flux/src/features/receive/application/server_controller.dart'
    show ServerController;
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:flux/src/features/receive/domain/transfer_progress.dart';
import 'package:flux/src/features/receive/domain/transfer_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_state.freezed.dart';

/// Information about a completed transfer.
class CompletedTransferInfo {
  /// Creates a [CompletedTransferInfo].
  const CompletedTransferInfo({
    required this.fileName,
    required this.fileSize,
    required this.savedPath,
    required this.completedAt,
  });

  /// Name of the transferred file.
  final String fileName;

  /// Size of the file in bytes.
  final int fileSize;

  /// Path where the file was saved.
  final String savedPath;

  /// When the transfer completed.
  final DateTime completedAt;
}

/// Root state for the file transfer server.
///
/// This is the state managed by [ServerController] and exposed to the UI.
@freezed
class ServerState with _$ServerState {
  /// Creates a new [ServerState] instance.
  const factory ServerState({
    /// Whether the HTTP server is currently running.
    @Default(false) bool isRunning,

    /// Whether the server is currently starting up.
    @Default(false) bool isStarting,

    /// Whether the server is currently stopping.
    @Default(false) bool isStopping,

    /// Port the server is bound to (null if not running).
    int? port,

    /// Whether discovery broadcast is active.
    @Default(false) bool isBroadcasting,

    /// Pending incoming request awaiting user decision.
    IncomingRequestEvent? pendingRequest,

    /// Current active transfer session (null if idle).
    TransferSession? activeSession,

    /// Progress of active transfer (null if idle).
    TransferProgress? transferProgress,

    /// Last error message (null if no error).
    String? error,

    /// Info about the last completed transfer (for brief display).
    CompletedTransferInfo? lastCompleted,
  }) = _ServerState;

  const ServerState._();

  /// Initial stopped state.
  factory ServerState.stopped() => const ServerState();

  /// Whether the server is idle (running but no active transfer).
  bool get isIdle =>
      isRunning && activeSession == null && pendingRequest == null;

  /// Whether the server is in a transitional state (starting or stopping).
  bool get isTransitioning => isStarting || isStopping;

  /// Whether there is a pending request awaiting user decision.
  bool get hasPendingRequest => pendingRequest != null;

  /// Whether a transfer is currently in progress.
  bool get isReceiving => activeSession != null && transferProgress != null;

  /// Whether a transfer just completed (for brief display).
  bool get hasRecentCompletion =>
      lastCompleted != null &&
      DateTime.now().difference(lastCompleted!.completedAt).inSeconds < 10;

  /// Human-readable status string.
  String get statusText {
    if (!isRunning) return 'Server stopped';
    if (isReceiving) return 'Receiving...';
    if (hasRecentCompletion) return 'Transfer complete!';
    return 'Waiting for transfers';
  }
}
