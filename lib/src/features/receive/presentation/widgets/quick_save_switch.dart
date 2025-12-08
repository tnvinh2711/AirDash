import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/receive_settings_provider.dart';

/// A switch for toggling the Quick Save feature.
///
/// When enabled, received files are automatically saved without
/// prompting the user for confirmation.
class QuickSaveSwitch extends ConsumerWidget {
  /// Creates a [QuickSaveSwitch] widget.
  const QuickSaveSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(receiveSettingsNotifierProvider);

    final isEnabled = settingsAsync.valueOrNull?.quickSaveEnabled ?? false;
    final isLoading = settingsAsync.isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Icon(
              isEnabled ? Icons.flash_on : Icons.flash_off,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              size: 28,
            ),
            const SizedBox(width: 16),

            // Label and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Save',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEnabled
                        ? 'Files saved automatically'
                        : 'Prompt before saving',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle switch
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: isEnabled,
                onChanged: (value) => _onToggle(ref, value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggle(WidgetRef ref, bool enabled) async {
    await ref
        .read(receiveSettingsNotifierProvider.notifier)
        .setQuickSave(enabled: enabled);
  }
}
