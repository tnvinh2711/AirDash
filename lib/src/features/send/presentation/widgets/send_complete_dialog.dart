import 'package:flutter/material.dart';
import 'package:flux/src/features/send/domain/transfer_result.dart';

/// Dialog shown after a successful file transfer completion.
///
/// Displays a list of all files that were sent successfully.
class SendCompleteDialog extends StatelessWidget {
  /// Creates a [SendCompleteDialog].
  const SendCompleteDialog({
    required this.results,
    required this.targetDeviceName,
    super.key,
  });

  /// The transfer results to display.
  final List<TransferResult> results;

  /// Name of the target device.
  final String targetDeviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successResults = results.where((r) => r.success).toList();
    final failedResults = results.where((r) => !r.success).toList();

    return AlertDialog(
      icon: Icon(
        failedResults.isEmpty ? Icons.check_circle : Icons.warning,
        color: failedResults.isEmpty
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
        size: 48,
      ),
      title: Text(
        failedResults.isEmpty
            ? 'Transfer Complete'
            : 'Transfer Partially Complete',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sent to $targetDeviceName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            // File list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (successResults.isNotEmpty) ...[
                    _buildSectionHeader(
                      theme,
                      'Sent Successfully (${successResults.length})',
                      theme.colorScheme.primary,
                    ),
                    ...successResults.map(
                      (r) => _buildFileItem(theme, r, true),
                    ),
                  ],
                  if (failedResults.isNotEmpty) ...[
                    if (successResults.isNotEmpty) const SizedBox(height: 12),
                    _buildSectionHeader(
                      theme,
                      'Failed (${failedResults.length})',
                      theme.colorScheme.error,
                    ),
                    ...failedResults.map(
                      (r) => _buildFileItem(theme, r, false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFileItem(ThemeData theme, TransferResult result, bool success) {
    final item = result.selectedItem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check : Icons.close,
            size: 16,
            color: success
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!success && result.error != null)
                  Text(
                    result.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatFileSize(item.sizeEstimate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Shows the send complete dialog.
void showSendCompleteDialog(
  BuildContext context, {
  required List<TransferResult> results,
  required String targetDeviceName,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => SendCompleteDialog(
      results: results,
      targetDeviceName: targetDeviceName,
    ),
  );
}
