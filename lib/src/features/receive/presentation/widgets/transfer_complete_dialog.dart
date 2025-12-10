import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/file_open_result.dart';
import 'package:flux/src/core/providers/file_open_service_provider.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';

/// Dialog shown after a successful file transfer completion.
///
/// Provides options to:
/// - Open the received file with the default app
/// - Show the file in the system file manager
/// - Dismiss the dialog
///
/// This dialog stays visible until the user explicitly dismisses it.
/// Multiple dialogs can be stacked for concurrent transfers.
class TransferCompleteDialog extends ConsumerWidget {
  /// Creates a [TransferCompleteDialog].
  const TransferCompleteDialog({required this.transfer, super.key});

  /// The completed transfer information.
  final CompletedTransferInfo transfer;

  /// Determines if this is a folder (directory) transfer.
  bool get _isFolder {
    try {
      return FileSystemEntity.isDirectorySync(transfer.savedPath);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFolder = _isFolder;

    return AlertDialog(
      icon: Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
        size: 48,
      ),
      title: const Text('Transfer Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Received: ${transfer.fileName}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _formatFileSize(transfer.fileSize),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () => _showInFolder(context, ref),
          child: const Text('Show in Folder'),
        ),
        FilledButton(
          onPressed: () => _openFile(context, ref),
          child: Text(isFolder ? 'Open Folder' : 'Open File'),
        ),
      ],
    );
  }

  /// Opens the file with the system's default application.
  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final fileOpenService = ref.read(fileOpenServiceProvider);
    final result = await fileOpenService.openFile(transfer.savedPath);

    if (!context.mounted) return;

    if (result.isFailure) {
      _showError(context, result);
    } else {
      Navigator.pop(context);
    }
  }

  /// Shows the file in the system file manager.
  Future<void> _showInFolder(BuildContext context, WidgetRef ref) async {
    final fileOpenService = ref.read(fileOpenServiceProvider);
    final result = await fileOpenService.showInFolder(transfer.savedPath);

    if (!context.mounted) return;

    if (result.isFailure) {
      _showError(context, result);
    } else {
      Navigator.pop(context);
    }
  }

  /// Shows an error snackbar.
  void _showError(BuildContext context, FileOpenResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'An error occurred'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Formats file size in human-readable format.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Shows the transfer complete dialog.
///
/// This is a helper function that can be called from anywhere to show
/// the completion popup. The dialog stays until dismissed.
void showTransferCompleteDialog(
  BuildContext context,
  CompletedTransferInfo transfer,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TransferCompleteDialog(transfer: transfer),
  );
}
