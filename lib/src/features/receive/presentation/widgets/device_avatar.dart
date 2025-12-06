import 'package:flutter/material.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';

/// Displays a device avatar icon based on the device type.
///
/// Shows appropriate icons for phone, tablet, laptop, desktop, or unknown
/// device types within a circular container.
class DeviceAvatar extends StatelessWidget {
  /// Creates a [DeviceAvatar] widget.
  const DeviceAvatar({
    required this.deviceType,
    this.size = 80,
    super.key,
  });

  /// The type of device to display.
  final DeviceType deviceType;

  /// The size of the avatar. Defaults to 80.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Icon(
        _getIconForDeviceType(deviceType),
        size: size * 0.5,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Returns the appropriate icon for a given device type.
  IconData _getIconForDeviceType(DeviceType type) {
    switch (type) {
      case DeviceType.phone:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet_mac;
      case DeviceType.laptop:
        return Icons.laptop_mac;
      case DeviceType.desktop:
        return Icons.desktop_mac;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }
}


