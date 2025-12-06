/// Transfer status enumeration.
///
/// Represents the final state of a file transfer operation.
enum TransferStatus {
  /// Transfer completed successfully.
  completed,

  /// Transfer failed due to an error.
  failed,

  /// Transfer was cancelled by the user.
  cancelled,
}
