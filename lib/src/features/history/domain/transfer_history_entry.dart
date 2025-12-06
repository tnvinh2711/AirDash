import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';

/// Represents a stored transfer history entry (read from database).
///
/// This is the full entity with all fields including auto-generated
/// `id` and `timestamp`.
class TransferHistoryEntry {
  /// Creates a [TransferHistoryEntry].
  const TransferHistoryEntry({
    required this.id,
    required this.transferId,
    required this.fileName,
    required this.fileCount,
    required this.totalSize,
    required this.fileType,
    required this.timestamp,
    required this.status,
    required this.direction,
    required this.remoteDeviceAlias,
  });

  /// Auto-incremented unique record identifier.
  final int id;

  /// UUID identifying the transfer session.
  final String transferId;

  /// Name of transferred file/folder.
  final String fileName;

  /// Number of files (>1 for folders).
  final int fileCount;

  /// Total size in bytes.
  final int totalSize;

  /// File type identifier (e.g., "pdf", "image", "folder").
  final String fileType;

  /// When transfer completed/failed.
  final DateTime timestamp;

  /// Completion status (completed, failed, cancelled).
  final TransferStatus status;

  /// Whether sent or received.
  final TransferDirection direction;

  /// Name of the other device.
  final String remoteDeviceAlias;
}
