import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/file_open_result.dart';
import 'package:flux/src/core/providers/file_open_service_provider.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_history_entry.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';

/// A list item displaying a single transfer history entry.
///
/// Shows direction icon, file name, device name, timestamp, and status.
/// Tappable entries (received with savedPath) can open the file.
/// Long-press shows context menu with "Open File" and "Show in Folder" options.
class HistoryListItem extends ConsumerWidget {
  /// Creates a [HistoryListItem] widget.
  const HistoryListItem({required this.entry, super.key});

  /// The transfer history entry to display.
  final TransferHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canOpen = entry.canOpenFile;

    return ListTile(
      leading: _buildDirectionIcon(theme),
      title: Text(entry.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${entry.remoteDeviceAlias} • ${_formatTimestamp(entry.timestamp)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: _buildTrailing(theme, canOpen),
      onTap: canOpen ? () => _handleTap(context, ref) : null,
      onLongPress: canOpen ? () => _showContextMenu(context, ref) : null,
    );
  }

  /// Builds the trailing widget with status and open indicator.
  Widget _buildTrailing(ThemeData theme, bool canOpen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(theme),
        if (canOpen) ...[
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
        ],
      ],
    );
  }

  /// Handles tap on a tappable history entry.
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final fileOpenService = ref.read(fileOpenServiceProvider);
    final result = await fileOpenService.openFile(entry.savedPath!);

    if (!context.mounted) return;

    if (result.isFailure) {
      _showErrorSnackbar(context, result);
    }
  }

  /// Shows context menu with file actions.
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Open File'),
              onTap: () {
                Navigator.pop(context);
                _handleTap(context, ref);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.folder_open,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Show in Folder'),
              onTap: () async {
                Navigator.pop(context);
                await _handleShowInFolder(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Handles "Show in Folder" action.
  Future<void> _handleShowInFolder(BuildContext context, WidgetRef ref) async {
    final fileOpenService = ref.read(fileOpenServiceProvider);
    final result = await fileOpenService.showInFolder(entry.savedPath!);

    if (!context.mounted) return;

    if (result.isFailure) {
      _showErrorSnackbar(context, result);
    }
  }

  /// Shows error snackbar for file open failures.
  void _showErrorSnackbar(BuildContext context, FileOpenResult result) {
    final message = result.errorMessage ?? 'An error occurred';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildDirectionIcon(ThemeData theme) {
    final isReceived = entry.direction == TransferDirection.received;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isReceived
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
      ),
      child: Icon(
        isReceived ? Icons.download : Icons.upload,
        color: isReceived
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer,
        size: 20,
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (entry.status) {
      case TransferStatus.completed:
        return Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
          size: 20,
        );
      case TransferStatus.failed:
        return Icon(Icons.error, color: theme.colorScheme.error, size: 20);
      case TransferStatus.cancelled:
        return Icon(Icons.cancel, color: theme.colorScheme.outline, size: 20);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
