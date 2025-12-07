import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';
import 'package:flux/src/features/send/application/transfer_controller.dart';
import 'package:flux/src/features/send/presentation/widgets/device_grid.dart';
import 'package:flux/src/features/send/presentation/widgets/drop_zone_overlay.dart';
import 'package:flux/src/features/send/presentation/widgets/selection_action_buttons.dart';
import 'package:flux/src/features/send/presentation/widgets/selection_list.dart';

/// The Send screen - displays content for sending files to peers.
///
/// Shows file selection controls, selected items list, and nearby devices grid.
/// Supports drag-and-drop on desktop platforms.
class SendScreen extends ConsumerStatefulWidget {
  /// Creates a [SendScreen] widget.
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  bool _isDragging = false;
  bool _hasStartedDiscovery = false;

  @override
  void initState() {
    super.initState();
    // Start discovery after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDiscovery();
    });
  }

  Future<void> _startDiscovery() async {
    if (_hasStartedDiscovery) return;
    _hasStartedDiscovery = true;

    // Get own IP address for self-filtering
    final ownIp = await ref.read(localIpAddressProvider.future);
    final controller = ref.read(discoveryControllerProvider.notifier)
      ..setOwnIpAddress(ownIp);
    await controller.startScan();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(fileSelectionControllerProvider);
    final isSelectionEmpty = selection.isEmpty;

    // Check if we're on desktop for drag-drop support
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    var body = _buildBody(isSelectionEmpty);

    // Wrap with DropTarget on desktop
    if (isDesktop) {
      body = DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: _handleDrop,
        child: Stack(
          children: [
            body,
            if (_isDragging) const DropZoneOverlay(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send'), centerTitle: true),
      body: body,
    );
  }

  Widget _buildBody(bool isSelectionEmpty) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selection action buttons
          const SelectionActionButtons(),
          const SizedBox(height: 16),

          // Selection list (takes available space)
          const Expanded(
            flex: 2,
            child: SelectionList(),
          ),
          const SizedBox(height: 16),

          // Device grid
          Expanded(
            flex: 3,
            child: DeviceGrid(
              isSelectionEmpty: isSelectionEmpty,
              onDeviceTap: _onDeviceTap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _isDragging = false);

    final paths = details.files.map((f) => f.path).toList();
    await ref.read(fileSelectionControllerProvider.notifier).addPaths(paths);
  }

  Future<void> _onDeviceTap(Device device) async {
    final selection = ref.read(fileSelectionControllerProvider);
    if (selection.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Files'),
        content: Text(
          'Send ${selection.length} item${selection.length == 1 ? '' : 's'} '
          'to ${device.alias}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Start transfer
    final results = await ref.read(transferControllerProvider.notifier).sendAll(
          items: selection,
          target: device,
        );

    // Clear selection on success
    final successCount = results.where((r) => r.success).length;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (successCount == results.length) {
      ref.read(fileSelectionControllerProvider.notifier).clear();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Successfully sent ${results.length} item(s)'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (successCount > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sent $successCount of ${results.length} item(s). '
            'Some transfers failed.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      final errorMsg = results.firstOrNull?.error ?? 'Unknown error';
      print('_SendScreenState._onDeviceTap $errorMsg');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Transfer failed: $errorMsg'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
