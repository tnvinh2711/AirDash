import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/widgets/toast_helper.dart';
import 'package:flux/src/core/widgets/transfer_status_bar.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';
import 'package:flux/src/features/send/application/transfer_controller.dart';
import 'package:flux/src/features/send/domain/transfer_result.dart';
import 'package:flux/src/features/send/domain/transfer_state.dart';
import 'package:flux/src/features/send/presentation/widgets/device_grid.dart';
import 'package:flux/src/features/send/presentation/widgets/drop_zone_overlay.dart';
import 'package:flux/src/features/send/presentation/widgets/selection_action_buttons.dart';
import 'package:flux/src/features/send/presentation/widgets/selection_list.dart';
import 'package:flux/src/features/send/presentation/widgets/send_complete_dialog.dart';

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

    // Listen for transfer completion/failure
    ref.listen<TransferState>(
      transferControllerProvider,
      _handleTransferStateChange,
    );

    // Check if we're on desktop for drag-drop support
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    var body = _buildBody(context, isSelectionEmpty);

    // Wrap with DropTarget on desktop
    if (isDesktop) {
      body = DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: _handleDrop,
        child: Stack(
          children: [body, if (_isDragging) const DropZoneOverlay()],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send'), centerTitle: true),
      body: Stack(
        children: [
          body,
          // Transfer status bar at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TransferStatusBar(),
          ),
        ],
      ),
    );
  }

  void _handleTransferStateChange(TransferState? previous, TransferState next) {
    switch (next) {
      case TransferStateCompleted(:final results, :final targetDeviceAlias):
        // Show completion dialog with file list
        showSendCompleteDialog(
          context,
          results: results,
          targetDeviceName: targetDeviceAlias,
        );
        // Clear selection after successful transfer
        ref.read(fileSelectionControllerProvider.notifier).clear();
      case TransferStateFailed(:final error):
        showErrorToast(context, error);
      case TransferStatePartialSuccess(
        :final results,
        :final targetDeviceAlias,
      ):
        // Show completion dialog with both success and failed files
        showSendCompleteDialog(
          context,
          results: results,
          targetDeviceName: targetDeviceAlias,
        );
        // Clear only successful items, keep failed ones for retry
        _clearSuccessfulItems(results);
      case TransferStateCancelled():
        showInfoToast(context, 'Transfer cancelled');
      default:
        break;
    }
  }

  /// Clears only the successfully transferred items from selection.
  void _clearSuccessfulItems(List<TransferResult> results) {
    final controller = ref.read(fileSelectionControllerProvider.notifier);
    for (final result in results) {
      if (result.success) {
        controller.removeItem(result.selectedItem.id);
      }
    }
  }

  Widget _buildBody(BuildContext context, bool isSelectionEmpty) {
    // Use MediaQuery instead of LayoutBuilder to avoid mutation conflicts
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width > 800;

    if (isWideScreen) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Selection
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SelectionActionButtons(),
                  const SizedBox(height: 16),
                  const Expanded(child: SelectionList()),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Right side: Devices
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

    // Mobile/narrow layout
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selection action buttons
          const SelectionActionButtons(),
          const SizedBox(height: 16),

          // Selection list (takes available space)
          const Expanded(flex: 2, child: SelectionList()),
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
    await ref
        .read(transferControllerProvider.notifier)
        .sendAll(items: selection, target: device);
  }
}
