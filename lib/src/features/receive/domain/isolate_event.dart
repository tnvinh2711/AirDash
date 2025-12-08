import 'package:freezed_annotation/freezed_annotation.dart';

part 'isolate_event.freezed.dart';

/// Events sent from server isolate to main isolate.
///
/// These events notify the UI layer about server state changes,
/// incoming requests, and transfer progress.
@freezed
sealed class IsolateEvent with _$IsolateEvent {
  /// Server successfully bound and listening.
  const factory IsolateEvent.serverStarted({required int port}) =
      ServerStartedEvent;

  /// Server has been shut down gracefully.
  const factory IsolateEvent.serverStopped() = ServerStoppedEvent;

  /// Error occurred during server operation.
  const factory IsolateEvent.serverError({required String message}) =
      ServerErrorEvent;

  /// Handshake received, awaiting user decision.
  ///
  /// Only emitted when quickSaveEnabled is false.
  const factory IsolateEvent.incomingRequest({
    /// Unique ID to correlate with RespondHandshake command.
    required String requestId,

    /// Sender device identifier.
    required String senderDeviceId,

    /// Sender display name.
    required String senderAlias,

    /// File name or folder name.
    required String fileName,

    /// Total size in bytes.
    required int fileSize,

    /// Number of files (1 for single file, >1 for folder).
    required int fileCount,

    /// True if this is a folder transfer (ZIP).
    required bool isFolder,
  }) = IncomingRequestEvent;

  /// Transfer progress update (throttled to max 10/sec).
  const factory IsolateEvent.transferProgress({
    required String sessionId,
    required int bytesReceived,
    required int totalBytes,
  }) = TransferProgressEvent;

  /// File successfully received and verified.
  const factory IsolateEvent.transferCompleted({
    required String sessionId,
    required String savedPath,
    required bool checksumVerified,
    // File metadata for history recording
    required String fileName,
    required int fileSize,
    required int fileCount,
    required String senderAlias,
  }) = TransferCompletedEvent;

  /// Transfer failed with error.
  const factory IsolateEvent.transferFailed({
    required String sessionId,
    required String reason,
    // File metadata for history recording (optional, may be null if error before handshake)
    String? fileName,
    int? fileSize,
    int? fileCount,
    String? senderAlias,
  }) = TransferFailedEvent;

  const IsolateEvent._();

  /// Converts to isolate-safe Map for transmission via SendPort.
  Map<String, dynamic> toMap() => switch (this) {
    ServerStartedEvent(:final port) => {'type': 'serverStarted', 'port': port},
    ServerStoppedEvent() => {'type': 'serverStopped'},
    ServerErrorEvent(:final message) => {
      'type': 'serverError',
      'message': message,
    },
    IncomingRequestEvent(
      :final requestId,
      :final senderDeviceId,
      :final senderAlias,
      :final fileName,
      :final fileSize,
      :final fileCount,
      :final isFolder,
    ) =>
      {
        'type': 'incomingRequest',
        'requestId': requestId,
        'senderDeviceId': senderDeviceId,
        'senderAlias': senderAlias,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileCount': fileCount,
        'isFolder': isFolder,
      },
    TransferProgressEvent(
      :final sessionId,
      :final bytesReceived,
      :final totalBytes,
    ) =>
      {
        'type': 'transferProgress',
        'sessionId': sessionId,
        'bytesReceived': bytesReceived,
        'totalBytes': totalBytes,
      },
    TransferCompletedEvent(
      :final sessionId,
      :final savedPath,
      :final checksumVerified,
      :final fileName,
      :final fileSize,
      :final fileCount,
      :final senderAlias,
    ) =>
      {
        'type': 'transferCompleted',
        'sessionId': sessionId,
        'savedPath': savedPath,
        'checksumVerified': checksumVerified,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileCount': fileCount,
        'senderAlias': senderAlias,
      },
    TransferFailedEvent(
      :final sessionId,
      :final reason,
      :final fileName,
      :final fileSize,
      :final fileCount,
      :final senderAlias,
    ) =>
      {
        'type': 'transferFailed',
        'sessionId': sessionId,
        'reason': reason,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileCount': fileCount,
        'senderAlias': senderAlias,
      },
  };

  /// Creates from isolate-received Map.
  static IsolateEvent fromMap(Map<String, dynamic> map) {
    return switch (map['type'] as String) {
      'serverStarted' => IsolateEvent.serverStarted(port: map['port'] as int),
      'serverStopped' => const IsolateEvent.serverStopped(),
      'serverError' => IsolateEvent.serverError(
        message: map['message'] as String,
      ),
      'incomingRequest' => IsolateEvent.incomingRequest(
        requestId: map['requestId'] as String,
        senderDeviceId: map['senderDeviceId'] as String,
        senderAlias: map['senderAlias'] as String,
        fileName: map['fileName'] as String,
        fileSize: map['fileSize'] as int,
        fileCount: map['fileCount'] as int,
        isFolder: map['isFolder'] as bool,
      ),
      'transferProgress' => IsolateEvent.transferProgress(
        sessionId: map['sessionId'] as String,
        bytesReceived: map['bytesReceived'] as int,
        totalBytes: map['totalBytes'] as int,
      ),
      'transferCompleted' => IsolateEvent.transferCompleted(
        sessionId: map['sessionId'] as String,
        savedPath: map['savedPath'] as String,
        checksumVerified: map['checksumVerified'] as bool,
        fileName: map['fileName'] as String,
        fileSize: map['fileSize'] as int,
        fileCount: map['fileCount'] as int,
        senderAlias: map['senderAlias'] as String,
      ),
      'transferFailed' => IsolateEvent.transferFailed(
        sessionId: map['sessionId'] as String,
        reason: map['reason'] as String,
        fileName: map['fileName'] as String?,
        fileSize: map['fileSize'] as int?,
        fileCount: map['fileCount'] as int?,
        senderAlias: map['senderAlias'] as String?,
      ),
      _ => throw ArgumentError('Unknown event type: ${map['type']}'),
    };
  }
}
