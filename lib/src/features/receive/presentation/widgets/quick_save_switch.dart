import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/receive_settings_provider.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';

/// A switch for toggling the Quick Save feature.
///
/// When enabled, received files are automatically saved without
/// prompting the user for confirmation.
///
/// Changing this setting restarts the server to apply the new configuration.
class QuickSaveSwitch extends ConsumerStatefulWidget {
  /// Creates a [QuickSaveSwitch] widget.
  const QuickSaveSwitch({super.key});

  @override
  ConsumerState<QuickSaveSwitch> createState() => _QuickSaveSwitchState();
}

class _QuickSaveSwitchState extends ConsumerState<QuickSaveSwitch> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(receiveSettingsNotifierProvider);

    final isEnabled = settingsAsync.valueOrNull?.quickSaveEnabled ?? false;
    final isLoading = settingsAsync.isLoading || _isToggling;

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
                onChanged: _onToggle,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onToggle(bool enabled) async {
    setState(() => _isToggling = true);

    try {
      // Update setting in database
      await ref
          .read(receiveSettingsNotifierProvider.notifier)
          .setQuickSave(enabled: enabled);

      // Restart server with new config to apply changes
      final serverController = ref.read(serverControllerProvider.notifier);
      final serverState = ref.read(serverControllerProvider).valueOrNull;

      if (serverState?.isRunning ?? false) {
        await serverController.stopServer();
        await serverController.startServer(quickSaveEnabled: enabled);
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }
}
