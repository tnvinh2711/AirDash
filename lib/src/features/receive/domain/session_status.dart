/// Session status enumeration for transfer sessions.
///
/// Represents the current state of an active transfer session.
enum SessionStatus {
  /// Session created, awaiting file upload.
  pending,

  /// File upload in progress.
  receiving,

  /// Transfer completed successfully.
  completed,

  /// Transfer failed due to an error.
  failed,

  /// Session expired due to timeout (5 minutes).
  expired,
}
