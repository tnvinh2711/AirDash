import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_result.freezed.dart';

/// Outcome of a single item transfer attempt.
@freezed
class TransferResult with _$TransferResult {
  /// Creates a new [TransferResult] instance.
  const factory TransferResult({
    /// Which item was transferred.
    required SelectedItem selectedItem,

    /// Whether transfer succeeded.
    required bool success,

    /// Error message if failed.
    String? error,

    /// Path on receiver (if success).
    String? savedPath,
  }) = _TransferResult;
}
