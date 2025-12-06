import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/discovery_state.dart';
import 'package:flux/src/features/send/presentation/widgets/device_grid_item.dart';

/// A responsive grid displaying discovered devices.
///
/// Shows a header with "Nearby Devices" title and refresh button,
/// followed by a grid of device cards. Handles empty and loading states.
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

        // Grid content
        Expanded(
          child: discoveryAsync.when(
            data: (state) => _buildGrid(context, state.devices),
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

  Widget _buildGrid(BuildContext context, List<Device> devices) {
    if (devices.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceGridItem(
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
