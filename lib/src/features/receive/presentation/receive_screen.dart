import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/routing/routes.dart';
import 'package:flux/src/core/widgets/circular_progress_card.dart';
import 'package:flux/src/core/widgets/elevated_card.dart';
import 'package:flux/src/core/widgets/glow_avatar.dart';
import 'package:flux/src/core/widgets/gradient_container.dart';
import 'package:flux/src/core/widgets/toast_helper.dart';
import 'package:flux/src/core/widgets/transfer_status_bar.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/receive/application/receive_settings_provider.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';
import 'package:flux/src/features/receive/presentation/widgets/pending_request_sheet.dart';
import 'package:flux/src/features/receive/presentation/widgets/transfer_complete_dialog.dart';
import 'package:go_router/go_router.dart';

/// The Receive screen - displays content for receiving files from peers.
///
/// Shows device identity, server toggle, quick save switch, and transfer
/// progress.
class ReceiveScreen extends ConsumerStatefulWidget {
  /// Creates a [ReceiveScreen] widget.
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  /// Track the currently shown pending request to avoid duplicate sheets.
  String? _shownRequestId;

  @override
  Widget build(BuildContext context) {
    final serverStateAsync = ref.watch(serverControllerProvider);

    // Listen for pending requests and show bottom sheet
    ref.listen<AsyncValue<ServerState>>(serverControllerProvider, (
      previous,
      next,
    ) {
      final pendingRequest = next.valueOrNull?.pendingRequest;
      _handlePendingRequest(pendingRequest);

      // Show toast on transfer completion or failure
      _handleTransferCompletion(previous, next);
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transfer History',
            onPressed: () => context.push(Routes.history),
          ),
        ],
      ),
      body: Stack(
        children: [
          serverStateAsync.when(
            data: (state) => _buildContent(context, state),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(serverControllerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
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

  void _handlePendingRequest(IncomingRequestEvent? request) {
    // Don't access context if widget is no longer mounted
    if (!mounted) return;

    if (request == null) {
      // Request was cleared (accepted/declined)
      _shownRequestId = null;
      return;
    }

    // Avoid showing duplicate sheets for the same request
    if (_shownRequestId == request.requestId) return;
    _shownRequestId = request.requestId;

    // Schedule after current frame to ensure context is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Show bottom sheet
      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PendingRequestSheet(request: request),
      ).then((_) {
        // Reset when sheet is closed
        _shownRequestId = null;
      });
    });
  }

  void _handleTransferCompletion(
    AsyncValue<ServerState>? previous,
    AsyncValue<ServerState> next,
  ) {
    // Don't access context if widget is no longer mounted
    if (!mounted) return;

    final prevState = previous?.valueOrNull;
    final nextState = next.valueOrNull;

    // Check for new completion
    if (nextState?.lastCompleted != null &&
        prevState?.lastCompleted != nextState?.lastCompleted) {
      // Schedule after current frame to ensure context is stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showTransferCompleteDialog(context, nextState!.lastCompleted!);
      });
    }

    // Check for new error (only show if not during transfer)
    if (nextState?.error != null &&
        prevState?.error != nextState?.error &&
        !nextState!.isReceiving) {
      // Schedule after current frame to ensure context is stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showErrorToast(context, nextState.error!);
      });
    }
  }

  Widget _buildContent(BuildContext context, ServerState state) {
    final theme = Theme.of(context);
    final identityAsync = ref.watch(deviceIdentityProvider);
    final settingsAsync = ref.watch(receiveSettingsNotifierProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero section with gradient background (full width)
          HeroGradientSection(
            height: 280,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glow avatar
                    identityAsync.when(
                      data: (identity) => GlowAvatar(
                        icon: Icons.phone_android,
                        isActive: state.isRunning,
                        size: 140,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Icon(Icons.error, size: 140),
                    ),
                    const SizedBox(height: 16),

                    // Device name
                    identityAsync.when(
                      data: (identity) => Text(
                        identity.alias,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),

                    // IP Address
                    identityAsync.when(
                      data: (identity) => Text(
                        identity.ipAddress ?? 'No IP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status chips section (centered with max width)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    StatusChip(
                      icon: state.isRunning ? Icons.check_circle : Icons.cancel,
                      label: state.isRunning ? 'Online' : 'Offline',
                      color: state.isRunning
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                    ),
                    settingsAsync.when(
                      data: (settings) => StatusChip(
                        icon: settings.quickSaveEnabled
                            ? Icons.flash_on
                            : Icons.flash_off,
                        label: settings.quickSaveEnabled
                            ? 'Quick Save ON'
                            : 'Quick Save OFF',
                        onTap: () => ref
                            .read(receiveSettingsNotifierProvider.notifier)
                            .toggleQuickSave(),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transfer progress card (centered with max width)
          if (state.isReceiving && state.transferProgress != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildProgressCard(context, state),
                ),
              ),
            ),

          // Error message (centered with max width)
          if (state.error != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedCard(
                    color: theme.colorScheme.errorContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 80), // Space for status bar
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, ServerState state) {
    final progress = state.transferProgress!;
    final session = state.activeSession;

    return CircularProgressCard(
      progress: progress.percentComplete / 100,
      title: session?.metadata.fileName ?? 'Receiving...',
      subtitle:
          session != null ? 'From: ${session.metadata.senderAlias}' : null,
      bytesTransferred: progress.bytesReceived,
      totalBytes: progress.totalBytes,
      speed: progress.bytesPerSecond,
    );
  }
}
