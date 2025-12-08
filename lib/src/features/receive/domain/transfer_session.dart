import 'package:flux/src/features/receive/domain/session_status.dart';
import 'package:flux/src/features/receive/domain/transfer_metadata.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_session.freezed.dart';

/// An active transfer session created after successful handshake.
///
/// Sessions are created when a handshake is received and follow the
/// state machine defined in [SessionStatus].
@freezed
class TransferSession with _$TransferSession {
  /// Creates a new [TransferSession] instance.
  const factory TransferSession({
    /// Unique session ID (UUID) assigned after accept.
    required String sessionId,

    /// Request ID for correlating handshake response.
    required String requestId,

    /// Transfer metadata from the handshake request.
    required TransferMetadata metadata,

    /// When the session was created.
    required DateTime createdAt,

    /// Current session status.
    required SessionStatus status,

    /// Failure reason if status is [SessionStatus.failed].
    String? failureReason,
  }) = _TransferSession;

  /// Creates a new session awaiting user acceptance.
  factory TransferSession.awaitingAccept({
    required String requestId,
    required TransferMetadata metadata,
  }) {
    return TransferSession(
      sessionId: '',
      // Assigned after accept
      requestId: requestId,
      metadata: metadata,
      createdAt: DateTime.now(),
      status: SessionStatus.awaitingAccept,
    );
  }

  /// Creates a new accepted session ready for upload.
  factory TransferSession.accepted({
    required String sessionId,
    required String requestId,
    required TransferMetadata metadata,
  }) {
    return TransferSession(
      sessionId: sessionId,
      requestId: requestId,
      metadata: metadata,
      createdAt: DateTime.now(),
      status: SessionStatus.accepted,
    );
  }

  const TransferSession._();

  /// Session timeout duration (5 minutes).
  static const timeout = Duration(minutes: 5);

  /// Whether the session has expired.
  bool get isExpired {
    return DateTime.now().difference(createdAt) > timeout;
  }

  /// Whether the session is in a terminal state.
  bool get isTerminal {
    return status == SessionStatus.completed ||
        status == SessionStatus.failed ||
        status == SessionStatus.cancelled;
  }
}
