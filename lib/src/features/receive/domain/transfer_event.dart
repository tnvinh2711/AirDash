import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/data/file_server_service.dart';
import 'package:flux/src/features/receive/domain/transfer_metadata.dart';

/// Events emitted by [FileServerService] for transfer state changes.
///
/// The [ServerController] subscribes to these events to update UI state.
sealed class TransferEvent {
  const TransferEvent();
}

/// Emitted when a handshake request is received.
class HandshakeReceivedEvent extends TransferEvent {
  /// Creates a [HandshakeReceivedEvent].
  const HandshakeReceivedEvent(this.metadata);

  /// The transfer metadata from the handshake request.
  final TransferMetadata metadata;
}

/// Emitted when a handshake is accepted and session created.
class HandshakeAcceptedEvent extends TransferEvent {
  /// Creates a [HandshakeAcceptedEvent].
  const HandshakeAcceptedEvent(this.sessionId);

  /// The generated session ID for the transfer.
  final String sessionId;
}

/// Emitted when a handshake is rejected.
class HandshakeRejectedEvent extends TransferEvent {
  /// Creates a [HandshakeRejectedEvent].
  const HandshakeRejectedEvent(this.reason);

  /// The rejection reason (e.g., "busy", "insufficient_storage").
  final String reason;
}

/// Emitted when file upload starts.
class UploadStartedEvent extends TransferEvent {
  /// Creates an [UploadStartedEvent].
  const UploadStartedEvent(this.sessionId);

  /// The session ID of the upload.
  final String sessionId;
}

/// Emitted periodically during file upload with progress.
class UploadProgressEvent extends TransferEvent {
  /// Creates an [UploadProgressEvent].
  const UploadProgressEvent({
    required this.bytesReceived,
    required this.totalBytes,
  });

  /// Bytes received so far.
  final int bytesReceived;

  /// Total expected bytes.
  final int totalBytes;
}

/// Emitted when file upload completes successfully.
class UploadCompletedEvent extends TransferEvent {
  /// Creates an [UploadCompletedEvent].
  const UploadCompletedEvent({
    required this.savedPath,
    required this.checksumVerified,
  });

  /// Path where the file was saved.
  final String savedPath;

  /// Whether checksum verification passed.
  final bool checksumVerified;
}

/// Emitted when file upload fails.
class UploadFailedEvent extends TransferEvent {
  /// Creates an [UploadFailedEvent].
  const UploadFailedEvent(this.reason);

  /// The failure reason.
  final String reason;
}
