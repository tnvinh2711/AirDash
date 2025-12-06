import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';

/// The Receive screen - displays content for receiving files from peers.
///
/// Shows server status, toggle button, and transfer progress when active.
class ReceiveScreen extends ConsumerWidget {
  /// Creates a [ReceiveScreen] widget.
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverStateAsync = ref.watch(serverControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        centerTitle: true,
      ),
      body: serverStateAsync.when(
        data: (state) => _buildContent(context, ref, state),
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
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ServerState state) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status icon
            _buildStatusIcon(state),
            const SizedBox(height: 24),

            // Status text
            Text(
              state.statusText,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Port info when running
            if (state.isRunning && state.port != null)
              Text(
                'Listening on port ${state.port}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),

            // Broadcast status
            if (state.isRunning)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isBroadcasting ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: state.isBroadcasting
                          ? Colors.green
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.isBroadcasting
                          ? 'Discoverable'
                          : 'Not discoverable',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.isBroadcasting
                            ? Colors.green
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

            // Transfer progress
            if (state.isReceiving && state.transferProgress != null) ...[
              const SizedBox(height: 24),
              _buildProgressIndicator(context, state),
            ],

            // Completed transfer info
            if (state.hasRecentCompletion && state.lastCompleted != null) ...[
              const SizedBox(height: 24),
              _buildCompletedInfo(context, state.lastCompleted!),
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

            const SizedBox(height: 32),

            // Toggle button
            _buildToggleButton(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ServerState state) {
    if (state.isReceiving) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(strokeWidth: 6),
      );
    }

    return Icon(
      state.isRunning ? Icons.download : Icons.download_outlined,
      size: 80,
      color: state.isRunning ? Colors.green : Colors.blueGrey,
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

  Widget _buildCompletedInfo(
    BuildContext context,
    CompletedTransferInfo info,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            info.fileName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatBytes(info.fileSize),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved to: ${info.savedPath}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.7,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    WidgetRef ref,
    ServerState state,
  ) {
    final controller = ref.read(serverControllerProvider.notifier);

    return FilledButton.icon(
      onPressed: state.isReceiving ? null : controller.toggleServer,
      icon: Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
      label: Text(state.isRunning ? 'Stop Server' : 'Start Server'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: state.isRunning ? Colors.red : null,
      ),
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
