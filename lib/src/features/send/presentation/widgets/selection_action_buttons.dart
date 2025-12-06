import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';

/// Action buttons for selecting files, folders, text, or media.
///
/// Displays a row of buttons that trigger the corresponding picker
/// in the [FileSelectionController].
class SelectionActionButtons extends ConsumerWidget {
  /// Creates a [SelectionActionButtons] widget.
  const SelectionActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.insert_drive_file_outlined,
          label: 'File',
          onPressed: () => _pickFiles(ref),
        ),
        _ActionButton(
          icon: Icons.folder_outlined,
          label: 'Folder',
          onPressed: () => _pickFolder(ref),
        ),
        _ActionButton(
          icon: Icons.text_snippet_outlined,
          label: 'Text',
          onPressed: () => _showTextDialog(context, ref),
        ),
        _ActionButton(
          icon: Icons.photo_library_outlined,
          label: 'Media',
          onPressed: () => _pickMedia(ref),
        ),
      ],
    );
  }

  Future<void> _pickFiles(WidgetRef ref) async {
    await ref.read(fileSelectionControllerProvider.notifier).pickFiles();
  }

  Future<void> _pickFolder(WidgetRef ref) async {
    await ref.read(fileSelectionControllerProvider.notifier).pickFolder();
  }

  Future<void> _pickMedia(WidgetRef ref) async {
    await ref.read(fileSelectionControllerProvider.notifier).pickMedia();
  }

  Future<void> _showTextDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Text'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter or paste text to send...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref
          .read(fileSelectionControllerProvider.notifier)
          .pasteText(result);
    }
  }
}

/// A single action button with icon and label.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
