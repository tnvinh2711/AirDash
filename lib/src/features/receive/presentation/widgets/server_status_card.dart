import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';

/// A card displaying the current server status (read-only).
///
/// The server auto-starts when the widget is first built.
class ServerStatusCard extends ConsumerStatefulWidget {
  /// Creates a [ServerStatusCard] widget.
  const ServerStatusCard({super.key});

  @override
  ConsumerState<ServerStatusCard> createState() => _ServerStatusCardState();
}

class _ServerStatusCardState extends ConsumerState<ServerStatusCard> {
  bool _hasTriggeredAutoStart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverStateAsync = ref.watch(serverControllerProvider);

    final serverState = serverStateAsync.valueOrNull;
    final isServerRunning = serverState?.isRunning ?? false;
    final isBroadcasting = serverState?.isBroadcasting ?? false;
    final isLoading = serverStateAsync.isLoading;

    // Auto-start server on first build (after initial state is available)
    if (!_hasTriggeredAutoStart && serverState != null && !isServerRunning && !isLoading) {
      _hasTriggeredAutoStart = true;
      // Schedule after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(serverControllerProvider.notifier).startServer();
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status icon with animation
            _buildStatusIcon(
              theme: theme,
              isServerRunning: isServerRunning,
              isBroadcasting: isBroadcasting,
              isLoading: isLoading,
            ),
            const SizedBox(width: 16),

            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receive Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusText(
                      isServerRunning: isServerRunning,
                      isBroadcasting: isBroadcasting,
                      isLoading: isLoading,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isServerRunning
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon({
    required ThemeData theme,
    required bool isServerRunning,
    required bool isBroadcasting,
    required bool isLoading,
  }) {
    if (isLoading) {
      return Icon(
        Icons.wifi_tethering,
        color: theme.colorScheme.outline,
        size: 28,
      );
    }

    return Icon(
      isServerRunning ? Icons.wifi_tethering : Icons.wifi_tethering_off,
      color: isServerRunning
          ? theme.colorScheme.primary
          : theme.colorScheme.outline,
      size: 28,
    );
  }

  String _getStatusText({
    required bool isServerRunning,
    required bool isBroadcasting,
    required bool isLoading,
  }) {
    if (isLoading) {
      return 'Starting...';
    }
    if (isServerRunning && isBroadcasting) {
      return 'Ready to receive files';
    }
    if (isServerRunning) {
      return 'Server ready, broadcasting...';
    }
    return 'Starting server...';
  }
}

