import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';

/// Action buttons for selecting files, folders, text, or media.
///
/// Displays a row of buttons that trigger the corresponding picker
/// in the [FileSelectionController].
class SelectionActionButtons extends ConsumerStatefulWidget {
  /// Creates a [SelectionActionButtons] widget.
  const SelectionActionButtons({super.key});

  @override
  ConsumerState<SelectionActionButtons> createState() =>
      _SelectionActionButtonsState();
}

class _SelectionActionButtonsState
    extends ConsumerState<SelectionActionButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      (Icons.insert_drive_file_outlined, 'File', () => _pickFiles(ref)),
      (Icons.folder_outlined, 'Folder', () => _pickFolder(ref)),
      (
        Icons.text_snippet_outlined,
        'Text',
        () => _showTextDialog(context, ref)
      ),
      (Icons.photo_library_outlined, 'Media', () => _pickMedia(ref)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(buttons.length, (index) {
        final (icon, label, onPressed) = buttons[index];
        // Staggered animation: each button starts 100ms after the previous
        final delay = index * 0.1;
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay,
            delay + 0.4,
            curve: Curves.easeOutBack,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: animation.value,
              child: Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _ActionButton(
            icon: icon,
            label: label,
            onPressed: onPressed,
          ),
        );
      }),
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
      ref.read(fileSelectionControllerProvider.notifier).pasteText(result);
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
