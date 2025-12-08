import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/device_identity.dart';
import 'package:flux/src/features/receive/presentation/widgets/device_avatar.dart';
import 'package:flux/src/features/receive/presentation/widgets/pulsing_avatar.dart';

/// Displays the device's identity information in a card layout.
///
/// Shows the device avatar, alias, IP address, and port. The IP address
/// is tappable to copy to clipboard. Shows "Not Connected" when offline.
class IdentityCard extends ConsumerWidget {
  /// Creates an [IdentityCard] widget.
  const IdentityCard({required this.isReceiving, super.key});

  /// Whether the device is currently in receiving mode.
  final bool isReceiving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(deviceIdentityProvider);
    final serverState = ref.watch(serverControllerProvider);

    // Get actual port from server state, fallback to identity port
    final actualPort = serverState.valueOrNull?.port;

    return identityAsync.when(
      data: (identity) => _buildCard(context, identity, actualPort),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    DeviceIdentity identity,
    int? actualPort,
  ) {
    final theme = Theme.of(context);
    // Use actual server port if available, otherwise fallback to identity port
    final displayPort = actualPort ?? identity.port;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing avatar with device icon
        PulsingAvatar(
          isActive: isReceiving,
          child: DeviceAvatar(deviceType: identity.deviceType),
        ),
        const SizedBox(height: 16),

        // Device alias
        Text(
          identity.alias,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Operating system
        Text(
          identity.os,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),

        // IP address (tappable)
        _buildIpAddressRow(context, identity.ipAddress),
        const SizedBox(height: 4),

        // Port (shows actual server port when running)
        Text(
          'Port: $displayPort',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildIpAddressRow(BuildContext context, String? ipAddress) {
    final theme = Theme.of(context);
    final hasIp = ipAddress != null;

    return InkWell(
      onTap: hasIp ? () => _copyIpAddress(context, ipAddress) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasIp ? Icons.content_copy : Icons.wifi_off,
              size: 16,
              color: hasIp
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              hasIp ? ipAddress : 'Not Connected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: hasIp
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyIpAddress(BuildContext context, String ip) async {
    await Clipboard.setData(ClipboardData(text: ip));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
