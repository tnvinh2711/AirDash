import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/routing/routes.dart';
import 'package:flux/src/core/widgets/toast_helper.dart';
import 'package:flux/src/core/widgets/transfer_status_bar.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';
import 'package:flux/src/features/receive/presentation/widgets/identity_card.dart';
import 'package:flux/src/features/receive/presentation/widgets/pending_request_sheet.dart';
import 'package:flux/src/features/receive/presentation/widgets/quick_save_switch.dart';
import 'package:flux/src/features/receive/presentation/widgets/server_status_card.dart';
import 'package:flux/src/features/receive/presentation/widgets/transfer_complete_dialog.dart';
import 'package:go_router/go_router.dart';

/// The Receive screen - displays content for receiving files from peers.
///
/// Shows device identity, server toggle, quick save switch, and transfer
/// progress.
class ReceiveScreen extends ConsumerStatefulWidget {
  /// Creates a [ReceiveScreen] widget.
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  /// Track the currently shown pending request to avoid duplicate sheets.
  String? _shownRequestId;

  @override
  Widget build(BuildContext context) {
    final serverStateAsync = ref.watch(serverControllerProvider);

    // Listen for pending requests and show bottom sheet
    ref.listen<AsyncValue<ServerState>>(serverControllerProvider, (
      previous,
      next,
    ) {
      final pendingRequest = next.valueOrNull?.pendingRequest;
      _handlePendingRequest(pendingRequest);

      // Show toast on transfer completion or failure
      _handleTransferCompletion(previous, next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transfer History',
            onPressed: () => context.push(Routes.history),
          ),
        ],
      ),
      body: Stack(
        children: [
          serverStateAsync.when(
            data: (state) => _buildContent(context, state),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(serverControllerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          // Transfer status bar at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TransferStatusBar(),
          ),
        ],
      ),
    );
  }

  void _handlePendingRequest(IncomingRequestEvent? request) {
    // Don't access context if widget is no longer mounted
    if (!mounted) return;

    if (request == null) {
      // Request was cleared (accepted/declined)
      _shownRequestId = null;
      return;
    }

    // Avoid showing duplicate sheets for the same request
    if (_shownRequestId == request.requestId) return;
    _shownRequestId = request.requestId;

    // Schedule after current frame to ensure context is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Show bottom sheet
      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PendingRequestSheet(request: request),
      ).then((_) {
        // Reset when sheet is closed
        _shownRequestId = null;
      });
    });
  }

  void _handleTransferCompletion(
    AsyncValue<ServerState>? previous,
    AsyncValue<ServerState> next,
  ) {
    // Don't access context if widget is no longer mounted
    if (!mounted) return;

    final prevState = previous?.valueOrNull;
    final nextState = next.valueOrNull;

    // Check for new completion
    if (nextState?.lastCompleted != null &&
        prevState?.lastCompleted != nextState?.lastCompleted) {
      // Schedule after current frame to ensure context is stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showTransferCompleteDialog(context, nextState!.lastCompleted!);
      });
    }

    // Check for new error (only show if not during transfer)
    if (nextState?.error != null &&
        prevState?.error != nextState?.error &&
        !nextState!.isReceiving) {
      // Schedule after current frame to ensure context is stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showErrorToast(context, nextState.error!);
      });
    }
  }

  Widget _buildContent(BuildContext context, ServerState state) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Identity Card with pulsing avatar
          IdentityCard(isReceiving: state.isRunning),
          const SizedBox(height: 32),

          // Server Status (read-only, auto-started)
          const ServerStatusCard(),
          const SizedBox(height: 16),

          // Quick Save Switch
          const QuickSaveSwitch(),

          // Transfer progress
          if (state.isReceiving && state.transferProgress != null) ...[
            const SizedBox(height: 24),
            _buildProgressIndicator(context, state),
          ],

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ServerState state) {
    final progress = state.transferProgress!;
    final session = state.activeSession;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Sender info
        if (session != null) ...[
          Text(
            'From: ${session.metadata.senderAlias}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          // File name
          Text(
            session.metadata.fileName,
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),

        // Progress bar
        LinearProgressIndicator(
          value: progress.percentComplete / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),

        // Progress text
        Text(
          '${progress.percentComplete}% - ${_formatBytes(progress.bytesReceived)} / ${_formatBytes(progress.totalBytes)}',
          style: theme.textTheme.bodySmall,
        ),

        // Transfer speed
        if (progress.bytesPerSecond > 0)
          Text(
            '${_formatBytes(progress.bytesPerSecond.round())}/s',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
