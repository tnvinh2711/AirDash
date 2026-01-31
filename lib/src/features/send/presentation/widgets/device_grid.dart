import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/widgets/elevated_card.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/discovery/domain/discovery_state.dart';

/// A list displaying discovered devices.
///
/// Shows a header with "Nearby Devices" title and refresh button,
/// followed by a list of device tiles. Handles empty and loading states.
class DeviceGrid extends ConsumerWidget {
  /// Creates a [DeviceGrid] widget.
  const DeviceGrid({
    required this.isSelectionEmpty,
    required this.onDeviceTap,
    super.key,
  });

  /// Whether the selection queue is empty (disables device taps).
  final bool isSelectionEmpty;

  /// Callback when a device is tapped.
  final void Function(Device device) onDeviceTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(discoveryControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(context, ref, discoveryAsync),
        const SizedBox(height: 8),

        // List content
        Expanded(
          child: discoveryAsync.when(
            data: (state) => _buildList(context, state.devices),
            loading: () => _buildLoading(context),
            error: (error, _) => _buildError(context, error),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DiscoveryState> discoveryAsync,
  ) {
    final theme = Theme.of(context);
    final isScanning = discoveryAsync.valueOrNull?.isScanning ?? false;

    return Row(
      children: [
        Text(
          'Nearby Devices',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (isScanning)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _refresh(ref),
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Device> devices) {
    if (devices.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _DeviceListTile(
          device: device,
          isEnabled: !isSelectionEmpty,
          onTap: () => onDeviceTap(device),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure other devices are running\nAirDash on the same network',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text('Error: $error'),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(discoveryControllerProvider.notifier).refresh();
  }
}

/// A list tile displaying a discovered device with elevated card design.
class _DeviceListTile extends StatelessWidget {
  const _DeviceListTile({
    required this.device,
    required this.isEnabled,
    required this.onTap,
  });

  final Device device;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        onTap: isEnabled ? onTap : null,
        elevation: 3,
        hoverElevation: 8,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Row(
            children: [
              // Device icon with gradient background
              _buildDeviceIcon(theme),
              const SizedBox(width: 16),

              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.alias,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            device.os,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.ip,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Send button
              if (isEnabled)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
            ],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 28,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}
