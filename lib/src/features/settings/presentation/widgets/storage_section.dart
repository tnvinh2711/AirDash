import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/settings/application/settings_controller.dart';

/// Storage settings section.
///
/// Allows users to configure download path.
class StorageSection extends ConsumerWidget {
  /// Creates a [StorageSection] widget.
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);

    return settingsAsync.when(
      data: (settings) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Storage',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Download Path
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Download Folder'),
                subtitle: Text(
                  settings.downloadPath ?? 'Default (Downloads)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.downloadPath != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Use default',
                        onPressed: () => ref
                            .read(settingsControllerProvider.notifier)
                            .clearDownloadPath(),
                      ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Choose folder',
                      onPressed: () => _pickDownloadFolder(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _pickDownloadFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
    );

    if (result != null) {
      await ref.read(settingsControllerProvider.notifier).setDownloadPath(result);
    }
  }
}

