import 'package:flutter/material.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_history_entry.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';

/// A list item displaying a single transfer history entry.
///
/// Shows direction icon, file name, device name, timestamp, and status.
class HistoryListItem extends StatelessWidget {
  /// Creates a [HistoryListItem] widget.
  const HistoryListItem({
    required this.entry,
    super.key,
  });

  /// The transfer history entry to display.
  final TransferHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildDirectionIcon(theme),
      title: Text(
        entry.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.remoteDeviceAlias} • ${_formatTimestamp(entry.timestamp)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: _buildStatusIcon(theme),
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
        return Icon(
          Icons.error,
          color: theme.colorScheme.error,
          size: 20,
        );
      case TransferStatus.cancelled:
        return Icon(
          Icons.cancel,
          color: theme.colorScheme.outline,
          size: 20,
        );
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

