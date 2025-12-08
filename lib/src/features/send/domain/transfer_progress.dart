import 'package:flux/src/features/send/domain/transfer_phase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_progress.freezed.dart';

/// Progress tracking for an active transfer.
@freezed
class TransferProgress with _$TransferProgress {
  /// Creates a new [TransferProgress] instance.
  const factory TransferProgress({
    /// Index in multi-item queue (0-based).
    required int currentItemIndex,

    /// Total items in queue.
    required int totalItems,

    /// Bytes sent for current item.
    required int bytesSent,

    /// Total bytes for current item.
    required int totalBytes,

    /// Current phase of transfer.
    required TransferPhase phase,
  }) = _TransferProgress;

  const TransferProgress._();

  /// Progress percentage (0-100) for current item.
  int get percentComplete {
    if (totalBytes <= 0) return 0;
    return ((bytesSent / totalBytes) * 100).round().clamp(0, 100);
  }

  /// Overall progress as fraction of total items.
  double get overallProgress {
    if (totalItems <= 0) return 0;
    final itemProgress = totalBytes > 0 ? bytesSent / totalBytes : 0;
    return (currentItemIndex + itemProgress) / totalItems;
  }
}
