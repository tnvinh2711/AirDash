import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';
import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';

/// A list tile displaying a single selected item.
///
/// Shows the item type icon, display name, size, and a remove button.
class SelectionItemTile extends ConsumerWidget {
  /// Creates a [SelectionItemTile] widget.
  const SelectionItemTile({
    required this.item,
    super.key,
  });

  /// The selected item to display.
  final SelectedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildTypeIcon(theme),
      title: Text(
        item.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatSize(item.sizeEstimate),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Remove',
        onPressed: () => _removeItem(ref),
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    final (icon, color) = switch (item.type) {
      SelectedItemType.file => (
          Icons.insert_drive_file,
          theme.colorScheme.primary,
        ),
      SelectedItemType.folder => (Icons.folder, Colors.amber),
      SelectedItemType.text => (Icons.text_snippet, Colors.teal),
      SelectedItemType.media => (Icons.photo, Colors.purple),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  void _removeItem(WidgetRef ref) {
    ref.read(fileSelectionControllerProvider.notifier).removeItem(item.id);
  }
}
