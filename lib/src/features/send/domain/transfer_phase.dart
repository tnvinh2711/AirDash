/// Current phase of transfer for a single item.
enum TransferPhase {
  /// Computing checksum, compressing folder.
  preparing,

  /// POST /api/v1/info in flight.
  handshaking,

  /// POST /api/v1/upload streaming.
  uploading,

  /// Waiting for server confirmation.
  verifying,
}
