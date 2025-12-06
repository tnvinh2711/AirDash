import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_progress.freezed.dart';

/// Real-time progress information for an active file transfer.
@freezed
class TransferProgress with _$TransferProgress {
  /// Creates a new [TransferProgress] instance.
  const factory TransferProgress({
    /// Number of bytes received and written to disk.
    required int bytesReceived,

    /// Expected total bytes (from metadata).
    required int totalBytes,

    /// When the upload started.
    required DateTime startedAt,
  }) = _TransferProgress;

  const TransferProgress._();

  /// Progress percentage (0-100).
  int get percentComplete {
    if (totalBytes <= 0) return 0;
    return ((bytesReceived / totalBytes) * 100).round().clamp(0, 100);
  }

  /// Bytes per second transfer rate.
  double get bytesPerSecond {
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed <= 0) return 0;
    return (bytesReceived / elapsed) * 1000;
  }

  /// Estimated time remaining in seconds.
  int get estimatedSecondsRemaining {
    final rate = bytesPerSecond;
    if (rate <= 0) return 0;
    final remaining = totalBytes - bytesReceived;
    return (remaining / rate).ceil();
  }

  /// Creates an initial progress instance.
  factory TransferProgress.start(int totalBytes) {
    return TransferProgress(
      bytesReceived: 0,
      totalBytes: totalBytes,
      startedAt: DateTime.now(),
    );
  }
}
