import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/send/application/transfer_controller.dart';
import 'package:flux/src/features/send/domain/transfer_state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_status_bar.freezed.dart';
part 'transfer_status_bar.g.dart';

/// State for the dedicated transfer status bar widget.
@freezed
class TransferStatusBarState with _$TransferStatusBarState {
  /// Creates a [TransferStatusBarState] instance.
  const factory TransferStatusBarState({
    /// Whether the status bar should be visible.
    required bool isVisible,

    /// True = sending, false = receiving.
    required bool isSending,

    /// Name of file being transferred.
    required String fileName,

    /// Bytes transferred so far.
    required int bytesTransferred,

    /// Total bytes to transfer.
    required int totalBytes,

    /// Progress from 0.0 to 1.0.
    required double progress,

    /// Name of the peer device.
    String? peerName,
  }) = _TransferStatusBarState;

  /// Hidden state.
  factory TransferStatusBarState.hidden() => const TransferStatusBarState(
    isVisible: false,
    isSending: false,
    fileName: '',
    bytesTransferred: 0,
    totalBytes: 0,
    progress: 0,
  );
}

/// Provides the current transfer status bar state.
///
/// Watches both server (receive) and transfer (send) controllers.
@riverpod
TransferStatusBarState transferStatusBar(Ref ref) {
  // Watch receive progress
  final serverState = ref.watch(serverControllerProvider).valueOrNull;
  if (serverState != null &&
      serverState.isReceiving &&
      serverState.transferProgress != null) {
    final progress = serverState.transferProgress!;
    return TransferStatusBarState(
      isVisible: true,
      isSending: false,
      fileName: serverState.activeSession?.metadata.fileName ?? 'File',
      bytesTransferred: progress.bytesReceived,
      totalBytes: progress.totalBytes,
      progress: progress.percentComplete / 100,
      peerName: serverState.activeSession?.metadata.senderAlias,
    );
  }

  // Watch send progress - TransferState is a sealed class with variants
  final transferState = ref.watch(transferControllerProvider);
  return switch (transferState) {
    TransferStateSending(:final progress) => TransferStatusBarState(
      isVisible: true,
      isSending: true,
      fileName: 'Sending...',
      bytesTransferred: progress.bytesSent,
      totalBytes: progress.totalBytes,
      progress: progress.percentComplete / 100,
    ),
    TransferStatePreparing(:final currentItem) => TransferStatusBarState(
      isVisible: true,
      isSending: true,
      fileName: currentItem.displayName,
      bytesTransferred: 0,
      totalBytes: 0,
      progress: 0,
    ),
    _ => TransferStatusBarState.hidden(),
  };
}

/// Dedicated transfer status bar widget.
///
/// Shows transfer progress at the bottom of the screen with slide animation.
class TransferStatusBar extends ConsumerWidget {
  /// Creates a [TransferStatusBar] widget.
  const TransferStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferStatusBarProvider);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: state.isVisible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: state.isVisible ? 1.0 : 0.0,
        child: _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransferStatusBarState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isSending ? Icons.upload : Icons.download,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: colorScheme.onPrimaryContainer.withValues(
                alpha: 0.2,
              ),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
