import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/settings/application/settings_controller.dart';

/// Device settings section.
///
/// Allows users to configure device alias and network port.
class DeviceSection extends ConsumerWidget {
  /// Creates a [DeviceSection] widget.
  const DeviceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final identityAsync = ref.watch(deviceIdentityProvider);
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
                  Icon(Icons.devices, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Device',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Device Alias
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Device Name'),
                subtitle: Text(
                  settings.deviceAlias ??
                      identityAsync.valueOrNull?.alias ??
                      'Loading...',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showAliasDialog(context, ref, settings.deviceAlias),
                ),
              ),
              const Divider(),

              // Network Port
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Network Port'),
                subtitle: Text('${settings.port ?? 8080}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showPortDialog(context, ref, settings.port),
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

  Future<void> _showAliasDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentAlias,
  ) async {
    final controller = TextEditingController(text: currentAlias);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter device name',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setDeviceAlias(result);
    }
  }

  Future<void> _showPortDialog(
    BuildContext context,
    WidgetRef ref,
    int? currentPort,
  ) async {
    final controller = TextEditingController(
      text: (currentPort ?? 8080).toString(),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Port'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter port (1-65535)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final port = int.tryParse(result);
      if (port != null && port >= 1 && port <= 65535) {
        await ref.read(settingsControllerProvider.notifier).setPort(port);
      }
    }
  }
}
