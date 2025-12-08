import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:flux/src/features/receive/data/server_isolate_entry.dart';
import 'package:flux/src/features/receive/domain/isolate_command.dart';
import 'package:flux/src/features/receive/domain/isolate_config.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_isolate_manager.g.dart';

/// Handshake timeout duration - increased from 10s to 30s for reliability.
const _handshakeTimeout = Duration(seconds: 30);

/// Maximum number of handshake retry attempts.
const _maxHandshakeRetries = 3;

/// Manages the server isolate lifecycle and bidirectional communication.
///
/// Spawns a background isolate to run the HTTP server, avoiding UI freezes
/// on Android where main isolate socket binding doesn't create OS sockets.
class ServerIsolateManager {
  /// Creates a [ServerIsolateManager].
  ServerIsolateManager();

  Isolate? _isolate;
  ReceivePort? _receivePort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  SendPort? _sendPort;
  StreamSubscription<dynamic>? _subscription;
  StreamSubscription<dynamic>? _errorSubscription;
  StreamSubscription<dynamic>? _exitSubscription;
  final _eventController = StreamController<IsolateEvent>.broadcast();

  /// Flag to prevent adding events after disposal.
  bool _disposed = false;

  /// Stream of events from the server isolate.
  Stream<IsolateEvent> get events => _eventController.stream;

  /// Whether the server isolate is currently running.
  bool get isRunning => _isolate != null;

  /// Starts the server isolate with the given configuration.
  ///
  /// Spawns a new isolate, establishes bidirectional communication,
  /// and sends the StartServer command. Retries up to [_maxHandshakeRetries]
  /// times on handshake timeout.
  Future<void> start(IsolateConfig config) async {
    if (_isolate != null) {
      developer.log(
        'Server isolate already running',
        name: 'ServerIsolateManager',
      );
      return;
    }

    // Reset disposed flag when starting
    _disposed = false;

    Exception? lastError;
    for (var attempt = 1; attempt <= _maxHandshakeRetries; attempt++) {
      try {
        await _startInternal(config, attempt);
        return; // Success
      } on Exception catch (e) {
        lastError = e;
        developer.log(
          'Start attempt $attempt/$_maxHandshakeRetries failed: $e',
          name: 'ServerIsolateManager',
          error: e,
        );
        if (attempt < _maxHandshakeRetries) {
          // Wait before retry
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    // All retries exhausted
    throw lastError ?? Exception('Failed to start server isolate');
  }

  /// Internal start implementation for retry logic.
  Future<void> _startInternal(IsolateConfig config, int attempt) async {
    developer.log(
      'Starting server isolate on port ${config.port} (attempt $attempt)',
      name: 'ServerIsolateManager',
    );

    // Create receive port for incoming messages from isolate
    _receivePort = ReceivePort();

    // Create ports for error and exit monitoring
    _errorPort = ReceivePort();
    _exitPort = ReceivePort();

    // Listen for isolate errors
    _errorSubscription = _errorPort!.listen((message) {
      developer.log(
        'Isolate error: $message',
        name: 'ServerIsolateManager',
        error: message,
      );
      _safeAddEvent(
        IsolateEvent.serverError(message: 'Isolate error: $message'),
      );
    });

    // Listen for isolate exit (crash detection)
    _exitSubscription = _exitPort!.listen((_) {
      developer.log(
        'Isolate exited unexpectedly',
        name: 'ServerIsolateManager',
      );
      if (_isolate != null) {
        // Unexpected exit - emit error event
        _safeAddEvent(
          const IsolateEvent.serverError(
            message: 'Server isolate crashed unexpectedly',
          ),
        );
        _safeAddEvent(const IsolateEvent.serverStopped());
        _cleanupWithoutKill();
      }
    });

    // Spawn the isolate with error and exit handlers
    // ignore: avoid_print
    print('[ServerIsolateManager] Spawning isolate...');
    _isolate = await Isolate.spawn(
      serverIsolateEntry,
      _receivePort!.sendPort,
      onError: _errorPort!.sendPort,
      onExit: _exitPort!.sendPort,
    );
    // ignore: avoid_print
    print('[ServerIsolateManager] Isolate spawned successfully');

    // Listen for messages from isolate
    final completer = Completer<SendPort>();
    _subscription = _receivePort!.listen((message) {
      // ignore: avoid_print
      print('[ServerIsolateManager] Received message: ${message.runtimeType}');
      if (message is SendPort) {
        // First message is the isolate's SendPort for bidirectional comm
        _sendPort = message;
        // ignore: avoid_print
        print('[ServerIsolateManager] Received SendPort from isolate');
        completer.complete(message);
      } else if (message is Map<String, dynamic>) {
        // Subsequent messages are events
        // ignore: avoid_print
        print('[ServerIsolateManager] Received event map: $message');
        try {
          final event = IsolateEvent.fromMap(message);
          _safeAddEvent(event);
        } catch (e) {
          developer.log(
            'Failed to parse event: $e',
            name: 'ServerIsolateManager',
            error: e,
          );
          // ignore: avoid_print
          print('[ServerIsolateManager] Failed to parse event: $e');
        }
      }
    });

    // Wait for handshake (SendPort from isolate) with retry logic
    // ignore: avoid_print
    print('[ServerIsolateManager] Waiting for SendPort handshake...');
    try {
      await completer.future.timeout(_handshakeTimeout);
      // ignore: avoid_print
      print('[ServerIsolateManager] Handshake complete');
    } on TimeoutException {
      developer.log(
        'Handshake timeout after ${_handshakeTimeout.inSeconds}s - isolate did not respond',
        name: 'ServerIsolateManager',
      );
      // ignore: avoid_print
      print('[ServerIsolateManager] Handshake TIMEOUT after ${_handshakeTimeout.inSeconds}s!');
      await _cleanup();
      throw Exception(
        'Server isolate handshake timeout after ${_handshakeTimeout.inSeconds}s',
      );
    }

    // Send start command
    // ignore: avoid_print
    print('[ServerIsolateManager] Sending StartServer command...');
    _sendCommand(IsolateCommand.startServer(config: config));
    // ignore: avoid_print
    print('[ServerIsolateManager] StartServer command sent');
  }

  /// Stops the server isolate gracefully.
  Future<void> stop() async {
    if (_isolate == null) return;

    developer.log('Stopping server isolate', name: 'ServerIsolateManager');

    _sendCommand(const IsolateCommand.stopServer());

    // Give isolate time to shut down gracefully
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await _cleanup();
  }

  /// Sends a handshake response to the isolate.
  void respondHandshake({required String requestId, required bool accepted}) {
    _sendCommand(IsolateCommand.respondHandshake(
      requestId: requestId,
      accepted: accepted,
    ));
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    // Set disposed flag first to prevent any new events
    _disposed = true;
    await stop();
    await _eventController.close();
  }

  /// Safely adds an event to the stream, guarding against disposed state.
  void _safeAddEvent(IsolateEvent event) {
    if (_disposed || _eventController.isClosed) {
      developer.log(
        'Ignoring event after disposal: ${event.runtimeType}',
        name: 'ServerIsolateManager',
      );
      return;
    }
    _eventController.add(event);
  }

  void _sendCommand(IsolateCommand command) {
    if (_sendPort == null) {
      developer.log(
        'Cannot send command - no SendPort',
        name: 'ServerIsolateManager',
      );
      return;
    }
    _sendPort!.send(command.toMap());
  }

  Future<void> _cleanup() async {
    // Set disposed flag to prevent race conditions during cleanup
    _disposed = true;
    await _cleanupWithoutKill();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  /// Cleans up resources without killing the isolate.
  /// Used when isolate has already exited unexpectedly.
  Future<void> _cleanupWithoutKill() async {
    // Set disposed flag first
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _errorSubscription?.cancel();
    _errorSubscription = null;
    await _exitSubscription?.cancel();
    _exitSubscription = null;
    _receivePort?.close();
    _receivePort = null;
    _errorPort?.close();
    _errorPort = null;
    _exitPort?.close();
    _exitPort = null;
    _sendPort = null;
    _isolate = null;
  }
}

/// Provides the [ServerIsolateManager] instance.
///
/// Uses [keepAlive: true] to prevent the manager from being disposed
/// when no widgets are watching it. This is critical because the server
/// isolate should persist as long as the app is running, not just when
/// the ReceiveScreen is visible.
@Riverpod(keepAlive: true)
ServerIsolateManager serverIsolateManager(ServerIsolateManagerRef ref) {
  final manager = ServerIsolateManager();
  ref.onDispose(() => manager.dispose());
  return manager;
}

