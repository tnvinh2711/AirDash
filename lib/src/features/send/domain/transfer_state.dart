import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/transfer_progress.dart';
import 'package:flux/src/features/send/domain/transfer_result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_state.freezed.dart';

/// Overall state of the transfer controller.
@freezed
sealed class TransferState with _$TransferState {
  /// No transfer in progress.
  const factory TransferState.idle() = TransferStateIdle;

  /// Preparing payload (compression, checksum).
  const factory TransferState.preparing({required SelectedItem currentItem}) =
      TransferStatePreparing;

  /// Actively transferring.
  const factory TransferState.sending({
    required TransferProgress progress,
    required List<TransferResult> results,
  }) = TransferStateSending;

  /// All items succeeded.
  const factory TransferState.completed({
    required List<TransferResult> results,
  }) = TransferStateCompleted;

  /// Some items failed.
  const factory TransferState.partialSuccess({
    required List<TransferResult> results,
  }) = TransferStatePartialSuccess;

  /// Critical failure (e.g., no network).
  const factory TransferState.failed({
    required String error,
    required List<TransferResult> results,
  }) = TransferStateFailed;

  /// User cancelled.
  const factory TransferState.cancelled({
    required List<TransferResult> results,
  }) = TransferStateCancelled;
}
