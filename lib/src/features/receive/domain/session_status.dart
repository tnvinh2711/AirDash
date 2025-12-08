/// Session status enumeration for transfer sessions.
///
/// Represents the current state of an active transfer session.
///
/// State transitions:
/// - awaitingAccept → accepted (user accepts)
/// - awaitingAccept → cancelled (user rejects or timeout)
/// - accepted → inProgress (upload starts)
/// - inProgress → completed (checksum verified)
/// - inProgress → failed (error during transfer)
/// - inProgress → cancelled (user cancels or sender disconnects)
enum SessionStatus {
  /// Handshake received, waiting for user decision.
  awaitingAccept,

  /// User accepted, ready for file upload.
  accepted,

  /// File upload in progress.
  inProgress,

  /// Transfer completed successfully.
  completed,

  /// Transfer failed due to an error.
  failed,

  /// Transfer cancelled by user or sender.
  cancelled,
}
