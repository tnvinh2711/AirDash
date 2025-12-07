/// Contract: ServerIsolateManager
///
/// Manages server isolate lifecycle and message routing.
///
/// Feature: 009-server-background-isolate
/// Date: 2025-12-07

// Expected implementation in: lib/src/features/receive/data/server_isolate_manager.dart

import 'dart:async';
import 'dart:isolate';

/// Manages the lifecycle of the server isolate.
///
/// Responsibilities:
/// 1. Spawn and terminate the server isolate
/// 2. Establish bidirectional SendPort/ReceivePort communication
/// 3. Route IsolateCommands to isolate
/// 4. Emit IsolateEvents as a broadcast stream
/// 5. Handle isolate crashes gracefully
abstract class ServerIsolateManager {
  /// Stream of events from the server isolate.
  ///
  /// This is a broadcast stream - multiple listeners allowed.
  /// Events are [IsolateEvent] instances converted from Maps.
  Stream<IsolateEvent> get events;

  /// Whether the server isolate is currently active.
  bool get isRunning;

  /// Spawn the server isolate and start the HTTP server.
  ///
  /// [config] contains the port, destination path, and Quick Save flag.
  ///
  /// Throws [StateError] if already running.
  /// Throws [IsolateSpawnException] if isolate fails to spawn.
  Future<void> start(IsolateConfig config);

  /// Send stop command and wait for graceful shutdown.
  ///
  /// Does nothing if not running.
  /// Waits up to 5 seconds for clean shutdown before force-killing.
  Future<void> stop();

  /// Send a command to the server isolate.
  ///
  /// [command] is converted to Map and sent via SendPort.
  /// Throws [StateError] if not running.
  void sendCommand(IsolateCommand command);

  /// Clean up resources.
  ///
  /// Stops the isolate if running and closes the event stream.
  void dispose();
}

/// Exception thrown when isolate fails to spawn.
class IsolateSpawnException implements Exception {
  final String message;
  IsolateSpawnException(this.message);

  @override
  String toString() => 'IsolateSpawnException: $message';
}

// ============================================================
// Implementation Notes
// ============================================================

/// Implementation should follow this pattern:
///
/// ```dart
/// class ServerIsolateManagerImpl implements ServerIsolateManager {
///   Isolate? _isolate;
///   ReceivePort? _receivePort;
///   SendPort? _sendPort;
///   final _eventController = StreamController<IsolateEvent>.broadcast();
///
///   @override
///   Stream<IsolateEvent> get events => _eventController.stream;
///
///   @override
///   bool get isRunning => _isolate != null;
///
///   @override
///   Future<void> start(IsolateConfig config) async {
///     if (isRunning) throw StateError('Already running');
///
///     _receivePort = ReceivePort();
///
///     _isolate = await Isolate.spawn(
///       _serverIsolateEntryPoint,
///       _receivePort!.sendPort,
///     );
///
///     // First message is the isolate's SendPort
///     _sendPort = await _receivePort!.first as SendPort;
///
///     // Listen for events
///     _receivePort!.listen((message) {
///       if (message is Map<String, dynamic>) {
///         final event = IsolateEvent.fromMap(message);
///         _eventController.add(event);
///       }
///     });
///
///     // Send start command
///     sendCommand(IsolateCommand.startServer(config: config));
///   }
///
///   @override
///   void sendCommand(IsolateCommand command) {
///     if (!isRunning) throw StateError('Not running');
///     _sendPort!.send(command.toMap());
///   }
///
///   @override
///   Future<void> stop() async {
///     if (!isRunning) return;
///     sendCommand(const IsolateCommand.stopServer());
///     // Wait for ServerStopped event or timeout
///     await events
///         .where((e) => e is ServerStoppedEvent)
///         .first
///         .timeout(Duration(seconds: 5), onTimeout: () => _forceKill());
///   }
///
///   void _forceKill() {
///     _isolate?.kill(priority: Isolate.immediate);
///     _cleanup();
///   }
///
///   void _cleanup() {
///     _receivePort?.close();
///     _isolate = null;
///     _sendPort = null;
///     _receivePort = null;
///   }
///
///   @override
///   void dispose() {
///     stop();
///     _eventController.close();
///   }
/// }
/// ```

// Placeholder types for contract compilation (not actual implementation)
class IsolateEvent {}
class IsolateConfig {}
class IsolateCommand {}

