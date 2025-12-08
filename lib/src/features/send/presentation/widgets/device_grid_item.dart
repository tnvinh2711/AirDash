import 'package:flutter/material.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';

/// A grid item displaying a discovered device.
///
/// Shows the device's OS icon, alias, and IP address. Can be tapped
/// to initiate a transfer when [isEnabled] is true.
class DeviceGridItem extends StatelessWidget {
  /// Creates a [DeviceGridItem] widget.
  const DeviceGridItem({
    required this.device,
    required this.isEnabled,
    required this.onTap,
    super.key,
  });

  /// The device to display.
  final Device device;

  /// Whether the item is tappable (false when selection is empty).
  final bool isEnabled;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Device type icon
                _buildDeviceIcon(theme),
                const SizedBox(height: 12),

                // Device alias
                Text(
                  device.alias,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // OS name
                Text(
                  device.os,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),

                // IP address
                Text(
                  device.ip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(ThemeData theme) {
    final icon = switch (device.deviceType) {
      DeviceType.phone => Icons.phone_android,
      DeviceType.tablet => Icons.tablet_android,
      DeviceType.laptop => Icons.laptop,
      DeviceType.desktop => Icons.desktop_windows,
      DeviceType.unknown => Icons.devices,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 32,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
