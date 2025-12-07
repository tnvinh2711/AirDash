import 'dart:async';
import 'dart:developer' as developer;

import 'package:flux/src/core/providers/device_info_provider.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:flux/src/features/receive/data/file_storage_service.dart';
import 'package:flux/src/features/receive/data/server_isolate_manager.dart';
import 'package:flux/src/features/receive/domain/isolate_config.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';
import 'package:flux/src/features/receive/domain/transfer_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_controller.g.dart';

/// Controller for managing the file transfer server lifecycle.
///
/// Coordinates the HTTP server with mDNS discovery broadcasting.
/// When the server starts, it also starts broadcasting via discovery.
/// When the server stops, it stops broadcasting.
///
/// Keep alive to prevent server and broadcast from stopping unexpectedly.
@Riverpod(keepAlive: true)
class ServerController extends _$ServerController {
  StreamSubscription<IsolateEvent>? _eventSubscription;

  @override
  Future<ServerState> build() async {
    ref.onDispose(_cleanup);
    return ServerState.stopped();
  }

  void _cleanup() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  ServerIsolateManager get _isolateManager =>
      ref.read(serverIsolateManagerProvider);

  /// Starts the HTTP server and discovery broadcast.
  ///
  /// If the server is already running, this is a no-op.
  /// If [destinationPath] is not provided, uses the platform-specific
  /// downloads/documents folder from [FileStorageService].
  Future<void> startServer({
    String? destinationPath,
    bool quickSaveEnabled = false,
  }) async {
    // ignore: avoid_print
    print('[ServerController] startServer called, quickSave=$quickSaveEnabled');
    final currentState = state.valueOrNull ?? ServerState.stopped();
    if (currentState.isRunning || state.isLoading) {
      // ignore: avoid_print
      print('[ServerController] Already running or loading, returning');
      return;
    }

    // Set loading state immediately for responsive UI
    state = const AsyncLoading<ServerState>().copyWithPrevious(state);
    // ignore: avoid_print
    print('[ServerController] Set loading state');

    try {
      // Get destination path from FileStorageService if not provided
      final actualDestinationPath = destinationPath ??
          await ref.read(fileStorageServiceProvider).getReceiveFolder();
      // ignore: avoid_print
      print('[ServerController] Destination path: $actualDestinationPath');

      // Pre-fetch device info in parallel with server start
      final deviceInfoFuture = _prefetchDeviceInfo();

      // Subscribe to isolate events before starting
      _eventSubscription = _isolateManager.events.listen(_handleIsolateEvent);
      // ignore: avoid_print
      print('[ServerController] Subscribed to isolate events');

      // Start server isolate
      const port = 53318; // Fixed port for now
      // ignore: avoid_print
      print('[ServerController] Calling _isolateManager.start()...');
      await _isolateManager.start(IsolateConfig(
        port: port,
        destinationPath: actualDestinationPath,
        quickSaveEnabled: quickSaveEnabled,
      ));
      // ignore: avoid_print
      print('[ServerController] _isolateManager.start() completed');

      developer.log(
        'Server isolate started on port $port',
        name: 'ServerController',
      );

      // Update state with running server (UI can update now)
      state = AsyncData(
        currentState.copyWith(
          isRunning: true,
          port: port,
          error: null,
        ),
      );
      // ignore: avoid_print
      print('[ServerController] State updated to running');

      // Start broadcast in background - fire and forget, don't block UI
      unawaited(_startBroadcastInBackground(deviceInfoFuture, port));
    } catch (e, stack) {
      developer.log(
        'Failed to start server: $e',
        name: 'ServerController',
        error: e,
      );
      // ignore: avoid_print
      print('[ServerController] FAILED to start server: $e\n$stack');
      state = AsyncData(
        currentState.copyWith(error: e.toString()),
      );
    }
  }

  Future<LocalDeviceInfo?> _prefetchDeviceInfo() async {
    try {
      final deviceInfoProvider = ref.read(deviceInfoProviderProvider);
      return await deviceInfoProvider.getLocalDeviceInfo();
    } catch (e) {
      developer.log(
        'Failed to get device info: $e',
        name: 'ServerController',
        level: 900,
      );
      return null;
    }
  }

  /// Stops the HTTP server and discovery broadcast.
  Future<void> stopServer() async {
    final currentState = state.valueOrNull ?? ServerState.stopped();
    if (!currentState.isRunning || state.isLoading) return;

    // Set loading state immediately for responsive UI
    state = const AsyncLoading<ServerState>().copyWithPrevious(state);

    try {
      // Stop discovery broadcast first
      await _stopBroadcast();

      // Cancel event subscription
      await _eventSubscription?.cancel();
      _eventSubscription = null;

      // Stop server isolate
      await _isolateManager.stop();

      // Update state
      state = AsyncData(
        ServerState.stopped(),
      );
    } catch (e) {
      developer.log(
        'Failed to stop server: $e',
        name: 'ServerController',
        error: e,
      );
      state = AsyncData(
        currentState.copyWith(error: e.toString()),
      );
    }
  }

  /// Toggles the server on/off.
  Future<void> toggleServer() async {
    final currentState = state.valueOrNull ?? ServerState.stopped();
    if (currentState.isRunning) {
      await stopServer();
    } else {
      await startServer();
    }
  }

  /// Starts mDNS broadcast in background without blocking UI.
  Future<void> _startBroadcastInBackground(
    Future<LocalDeviceInfo?> deviceInfoFuture,
    int port,
  ) async {
    try {
      final deviceInfo = await deviceInfoFuture;
      if (deviceInfo == null) return;

      final infoWithPort = deviceInfo.copyWith(port: port);

      // Ensure discovery controller is ready
      await ref.read(discoveryControllerProvider.future);

      final discoveryController = ref.read(
        discoveryControllerProvider.notifier,
      );

      await discoveryController.startBroadcast(infoWithPort);

      // Update broadcast state
      final newState = state.valueOrNull;
      if (newState != null) {
        state = AsyncData(newState.copyWith(isBroadcasting: true));
      }
    } catch (e) {
      developer.log(
        'Failed to start broadcast: $e',
        name: 'ServerController',
        level: 900,
      );
    }
  }

  Future<void> _stopBroadcast() async {
    try {
      final discoveryController = ref.read(
        discoveryControllerProvider.notifier,
      );
      await discoveryController.stopBroadcast();

      final currentState = state.valueOrNull ?? ServerState.stopped();
      state = AsyncData(currentState.copyWith(isBroadcasting: false));
    } catch (e) {
      developer.log(
        'Failed to stop discovery broadcast: $e',
        name: 'ServerController',
        level: 900,
      );
    }
  }

  /// Accepts a pending incoming request.
  void acceptRequest(String requestId) {
    _isolateManager.respondHandshake(requestId: requestId, accepted: true);

    // Clear pending request from state
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(pendingRequest: null),
      );
    }
  }

  /// Rejects a pending incoming request.
  void rejectRequest(String requestId) {
    _isolateManager.respondHandshake(requestId: requestId, accepted: false);

    // Clear pending request from state
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(pendingRequest: null),
      );
    }
  }

  void _handleIsolateEvent(IsolateEvent event) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    switch (event) {
      case ServerStartedEvent(:final port):
        developer.log(
          'Server started on port $port',
          name: 'ServerController',
        );
        state = AsyncData(
          currentState.copyWith(
            isRunning: true,
            port: port,
            error: null,
          ),
        );
      case ServerStoppedEvent():
        developer.log('Server stopped', name: 'ServerController');
        state = AsyncData(ServerState.stopped());
      case ServerErrorEvent(:final message):
        developer.log(
          'Server error: $message',
          name: 'ServerController',
          error: message,
        );
        state = AsyncData(
          currentState.copyWith(error: message),
        );
      case IncomingRequestEvent() && final request:
        // Show pending request to user
        state = AsyncData(
          currentState.copyWith(pendingRequest: request),
        );
      case TransferProgressEvent(
          :final bytesReceived,
          :final totalBytes,
          sessionId: _,
        ):
        final existingProgress = currentState.transferProgress;
        state = AsyncData(
          currentState.copyWith(
            transferProgress: TransferProgress(
              bytesReceived: bytesReceived,
              totalBytes: totalBytes,
              startedAt: existingProgress?.startedAt ?? DateTime.now(),
            ),
          ),
        );
      case TransferCompletedEvent(:final savedPath, sessionId: _):
        final session = currentState.activeSession;
        state = AsyncData(
          currentState.copyWith(
            activeSession: null,
            transferProgress: null,
            lastCompleted: session != null
                ? CompletedTransferInfo(
                    fileName: session.metadata.fileName,
                    fileSize: session.metadata.fileSize,
                    savedPath: savedPath,
                    completedAt: DateTime.now(),
                  )
                : CompletedTransferInfo(
                    fileName: 'File',
                    fileSize: 0,
                    savedPath: savedPath,
                    completedAt: DateTime.now(),
                  ),
          ),
        );
      case TransferFailedEvent(:final reason, sessionId: _):
        state = AsyncData(
          currentState.copyWith(
            activeSession: null,
            transferProgress: null,
            error: reason,
          ),
        );
    }
  }
}
