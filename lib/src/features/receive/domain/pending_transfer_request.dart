import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_transfer_request.freezed.dart';

/// Represents an incoming transfer request awaiting user decision.
///
/// Used when Quick Save is disabled to show the accept/decline bottom sheet.
@freezed
class PendingTransferRequest with _$PendingTransferRequest {
  /// Creates a [PendingTransferRequest] instance.
  const factory PendingTransferRequest({
    /// Unique identifier for this request.
    required String requestId,

    /// Human-readable sender name.
    required String senderAlias,

    /// mDNS device ID of sender.
    required String senderDeviceId,

    /// Name of file/folder being sent.
    required String fileName,

    /// Total size in bytes.
    required int fileSize,

    /// MIME type of the file.
    required String fileType,

    /// True if sending a folder (ZIP).
    required bool isFolder,

    /// Number of files (1 for single file).
    required int fileCount,

    /// Timestamp for timeout calculation.
    required DateTime receivedAt,
  }) = _PendingTransferRequest;

  const PendingTransferRequest._();

  /// Time remaining before auto-decline (30 second timeout).
  Duration get timeRemaining {
    final elapsed = DateTime.now().difference(receivedAt);
    final remaining = const Duration(seconds: 30) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether the request has timed out.
  bool get hasTimedOut => timeRemaining == Duration.zero;
}
