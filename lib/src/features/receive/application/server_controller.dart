import 'dart:async';
import 'dart:developer' as developer;

import 'package:flux/src/core/providers/device_info_provider.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/receive/data/file_server_service.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';
import 'package:flux/src/features/receive/domain/transfer_event.dart';
import 'package:flux/src/features/receive/domain/transfer_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_controller.g.dart';

/// Controller for managing the file transfer server lifecycle.
///
/// Coordinates the HTTP server with mDNS discovery broadcasting.
/// When the server starts, it also starts broadcasting via discovery.
/// When the server stops, it stops broadcasting.
@riverpod
class ServerController extends _$ServerController {
  StreamSubscription<TransferEvent>? _eventSubscription;

  @override
  Future<ServerState> build() async {
    ref.onDispose(_cleanup);
    return ServerState.stopped();
  }

  void _cleanup() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  FileServerService get _fileServer => ref.read(fileServerServiceProvider);

  /// Starts the HTTP server and discovery broadcast.
  ///
  /// If the server is already running, this is a no-op.
  Future<void> startServer() async {
    final currentState = state.valueOrNull ?? ServerState.stopped();
    if (currentState.isRunning) return;

    try {
      // Start HTTP server
      final port = await _fileServer.start();

      // Subscribe to transfer events
      _eventSubscription = _fileServer.events.listen(_handleTransferEvent);

      // Update state with running server
      state = AsyncData(
        currentState.copyWith(
          isRunning: true,
          port: port,
          error: null,
        ),
      );

      // Start discovery broadcast
      await _startBroadcast(port);
    } catch (e) {
      developer.log(
        'Failed to start server: $e',
        name: 'ServerController',
        error: e,
      );
      state = AsyncData(currentState.copyWith(error: e.toString()));
    }
  }

  /// Stops the HTTP server and discovery broadcast.
  Future<void> stopServer() async {
    final currentState = state.valueOrNull ?? ServerState.stopped();
    if (!currentState.isRunning) return;

    try {
      // Stop discovery broadcast first
      await _stopBroadcast();

      // Cancel event subscription
      await _eventSubscription?.cancel();
      _eventSubscription = null;

      // Stop HTTP server
      await _fileServer.stop();

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
      state = AsyncData(currentState.copyWith(error: e.toString()));
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

  Future<void> _startBroadcast(int port) async {
    try {
      final deviceInfoProvider = ref.read(deviceInfoProviderProvider);
      final deviceInfo = await deviceInfoProvider.getLocalDeviceInfo();
      final infoWithPort = deviceInfo.copyWith(port: port);

      final discoveryController = ref.read(
        discoveryControllerProvider.notifier,
      );
      await discoveryController.startBroadcast(infoWithPort);

      final currentState = state.valueOrNull ?? ServerState.stopped();
      state = AsyncData(currentState.copyWith(isBroadcasting: true));
    } catch (e) {
      // Log warning but don't fail - server can still work without broadcast
      developer.log(
        'Failed to start discovery broadcast: $e',
        name: 'ServerController',
        level: 900, // Warning level
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

  void _handleTransferEvent(TransferEvent event) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    switch (event) {
      case UploadStartedEvent(:final sessionId):
        // Get session from file server if needed
        final session = _fileServer.getSession(sessionId);
        if (session != null) {
          state = AsyncData(
            currentState.copyWith(
              activeSession: session,
              transferProgress: TransferProgress.start(
                session.metadata.fileSize,
              ),
            ),
          );
        }
      case UploadProgressEvent(:final bytesReceived, :final totalBytes):
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
      case UploadCompletedEvent(:final savedPath):
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
                : null,
          ),
        );
      case UploadFailedEvent(:final reason):
        state = AsyncData(
          currentState.copyWith(
            activeSession: null,
            transferProgress: null,
            error: reason,
          ),
        );
      case HandshakeReceivedEvent() ||
            HandshakeAcceptedEvent() ||
            HandshakeRejectedEvent():
        // No state change needed for handshake events
        break;
    }
  }
}
