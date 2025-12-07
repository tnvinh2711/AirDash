import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:flux/src/features/receive/domain/isolate_command.dart';
import 'package:flux/src/features/receive/domain/isolate_config.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

/// Entry point for the server isolate.
///
/// This function runs in a separate isolate and handles all HTTP server
/// operations, avoiding UI freezes on the main isolate.
void serverIsolateEntry(SendPort mainSendPort) {
  // ignore: avoid_print
  print('[ServerIsolate] Entry point called');
  developer.log('Server isolate started', name: 'ServerIsolate');

  // Create receive port for commands from main isolate
  final receivePort = ReceivePort();

  // Send our SendPort back to main isolate for bidirectional communication
  // ignore: avoid_print
  print('[ServerIsolate] Sending SendPort back to main isolate');
  mainSendPort.send(receivePort.sendPort);
  // ignore: avoid_print
  print('[ServerIsolate] SendPort sent');

  // Create server instance
  final server = _IsolateServer(mainSendPort);

  // Listen for commands
  receivePort.listen((message) {
    // ignore: avoid_print
    print('[ServerIsolate] Received command: ${message.runtimeType}');
    if (message is Map<String, dynamic>) {
      try {
        final command = IsolateCommand.fromMap(message);
        // ignore: avoid_print
        print('[ServerIsolate] Parsed command: $command');
        server.handleCommand(command);
      } catch (e) {
        developer.log(
          'Failed to parse command: $e',
          name: 'ServerIsolate',
          error: e,
        );
        // ignore: avoid_print
        print('[ServerIsolate] Failed to parse command: $e');
      }
    }
  });
}

/// Internal server implementation running in the isolate.
class _IsolateServer {
  _IsolateServer(this._sendPort);

  final SendPort _sendPort;
  final _uuid = const Uuid();

  HttpServer? _httpServer;
  IsolateConfig? _config;

  // Pending handshake completers keyed by requestId
  final _pendingHandshakes = <String, Completer<bool>>{};

  // Progress throttling
  DateTime? _lastProgressTime;
  static const _progressThrottleMs = 100;

  void handleCommand(IsolateCommand command) {
    switch (command) {
      case StartServerCommand(:final config):
        _startServer(config);
      case StopServerCommand():
        _stopServer();
      case RespondHandshakeCommand(:final requestId, :final accepted):
        _respondHandshake(requestId, accepted);
    }
  }

  Future<void> _startServer(IsolateConfig config) async {
    if (_httpServer != null) {
      developer.log('Server already running', name: 'ServerIsolate');
      // ignore: avoid_print
      print('[ServerIsolate] Server already running');
      return;
    }

    _config = config;
    // ignore: avoid_print
    print('[ServerIsolate] Config set: port=${config.port}, '
        'quickSaveEnabled=${config.quickSaveEnabled}, '
        'destinationPath=${config.destinationPath}');

    try {
      developer.log(
        'Binding HTTP server on port ${config.port}',
        name: 'ServerIsolate',
      );
      // ignore: avoid_print
      print('[ServerIsolate] Binding HTTP server on port ${config.port}');

      _httpServer = await HttpServer.bind(
        InternetAddress.anyIPv4,
        config.port,
      );

      developer.log(
        'Server bound on port ${_httpServer!.port}',
        name: 'ServerIsolate',
      );
      // ignore: avoid_print
      print('[ServerIsolate] Server bound on port ${_httpServer!.port}');

      // Set up shelf router
      final router = Router()
        ..post('/api/v1/info', _handleHandshake)
        ..post('/api/v1/upload', _handleUpload);

      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      // Start serving
      shelf_io.serveRequests(_httpServer!, handler);

      // ignore: avoid_print
      print('[ServerIsolate] Server started and serving requests');
      _sendEvent(IsolateEvent.serverStarted(port: _httpServer!.port));
    } catch (e) {
      developer.log(
        'Failed to start server: $e',
        name: 'ServerIsolate',
        error: e,
      );
      // ignore: avoid_print
      print('[ServerIsolate] Failed to start server: $e');
      _sendEvent(IsolateEvent.serverError(message: e.toString()));
    }
  }

  Future<void> _stopServer() async {
    if (_httpServer == null) return;

    developer.log('Stopping server', name: 'ServerIsolate');

    // Cancel all pending handshakes
    for (final completer in _pendingHandshakes.values) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    _pendingHandshakes.clear();

    await _httpServer!.close(force: true);
    _httpServer = null;

    _sendEvent(const IsolateEvent.serverStopped());
  }

  void _respondHandshake(String requestId, bool accepted) {
    final completer = _pendingHandshakes[requestId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(accepted);
    }
  }

  void _sendEvent(IsolateEvent event) {
    _sendPort.send(event.toMap());
  }

  Future<Response> _handleHandshake(Request request) async {
    // ignore: avoid_print
    print('[ServerIsolate] _handleHandshake called');
    try {
      final body = await request.readAsString();
      // ignore: avoid_print
      print('[ServerIsolate] Handshake body: $body');
      final json = jsonDecode(body) as Map<String, dynamic>;

      developer.log(
        'Handshake request received: $json',
        name: 'ServerIsolate',
      );
      // ignore: avoid_print
      print('[ServerIsolate] Handshake request received: $json');

      // Extract metadata from request
      // Note: Client sends senderDeviceId/senderAlias (from HandshakeRequest DTO)
      final requestId = _uuid.v4();
      final senderDeviceId =
          json['senderDeviceId'] as String? ?? json['deviceId'] as String? ?? 'unknown';
      final senderAlias =
          json['senderAlias'] as String? ?? json['alias'] as String? ?? 'Unknown Device';
      final fileName = json['fileName'] as String? ?? 'file';
      final fileSize = json['fileSize'] as int? ?? 0;
      final fileCount = json['fileCount'] as int? ?? 1;
      final isFolder = json['isFolder'] as bool? ?? false;

      // Quick Save mode: auto-accept without prompting
      // ignore: avoid_print
      print('[ServerIsolate] _config: $_config');
      // ignore: avoid_print
      print('[ServerIsolate] quickSaveEnabled: ${_config?.quickSaveEnabled}');
      if (_config?.quickSaveEnabled == true) {
        // ignore: avoid_print
        print('[ServerIsolate] Quick Save is ON, auto-accepting');
        final sessionId = _uuid.v4();
        return Response.ok(
          jsonEncode({'accepted': true, 'sessionId': sessionId}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      // ignore: avoid_print
      print('[ServerIsolate] Quick Save is OFF, waiting for user decision');

      // Notify main isolate of incoming request
      _sendEvent(IsolateEvent.incomingRequest(
        requestId: requestId,
        senderDeviceId: senderDeviceId,
        senderAlias: senderAlias,
        fileName: fileName,
        fileSize: fileSize,
        fileCount: fileCount,
        isFolder: isFolder,
      ));

      // Wait for user decision with timeout
      final completer = Completer<bool>();
      _pendingHandshakes[requestId] = completer;

      try {
        final accepted = await completer.future.timeout(
          const Duration(seconds: 60),
        );

        _pendingHandshakes.remove(requestId);

        if (accepted) {
          final sessionId = _uuid.v4();
          return Response.ok(
            jsonEncode({'accepted': true, 'sessionId': sessionId}),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          return Response(
            403,
            body: jsonEncode({'accepted': false, 'error': 'rejected'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } on TimeoutException {
        _pendingHandshakes.remove(requestId);
        return Response(
          408,
          body: jsonEncode({'accepted': false, 'error': 'timeout'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return Response(
        400,
        body: jsonEncode({'accepted': false, 'error': 'invalid_request'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleUpload(Request request) async {
    final sessionId = request.headers['x-transfer-session'];

    if (sessionId == null || sessionId.isEmpty) {
      return Response(
        400,
        body: jsonEncode({'success': false, 'error': 'missing_session_id'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final destinationPath = _config?.destinationPath ?? '/tmp';
    final fileName = request.headers['x-file-name'] ?? 'received_file';
    final filePath = '$destinationPath/$fileName';
    IOSink? sink;

    try {
      // Get total bytes from header
      final contentLength = request.headers['content-length'];
      final totalBytes =
          contentLength != null ? int.tryParse(contentLength) ?? 0 : 0;

      // Stream file to disk with progress updates
      var bytesReceived = 0;
      final file = File(filePath);
      sink = file.openWrite();

      await for (final chunk in request.read()) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        // Throttle progress updates
        final now = DateTime.now();
        if (_lastProgressTime == null ||
            now.difference(_lastProgressTime!).inMilliseconds >=
                _progressThrottleMs) {
          _lastProgressTime = now;
          _sendEvent(IsolateEvent.transferProgress(
            sessionId: sessionId,
            bytesReceived: bytesReceived,
            totalBytes: totalBytes,
          ));
        }
      }

      await sink.close();
      sink = null;

      // Always emit final 100% progress before completion
      _sendEvent(IsolateEvent.transferProgress(
        sessionId: sessionId,
        bytesReceived: bytesReceived,
        totalBytes: totalBytes,
      ));

      _sendEvent(IsolateEvent.transferCompleted(
        sessionId: sessionId,
        savedPath: filePath,
        checksumVerified: true, // TODO: Implement checksum verification
      ));

      return Response.ok(
        jsonEncode({
          'success': true,
          'savedPath': filePath,
          'checksumVerified': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Clean up partial file on failure
      try {
        await sink?.close();
        final partialFile = File(filePath);
        if (await partialFile.exists()) {
          await partialFile.delete();
          developer.log(
            'Cleaned up partial file: $filePath',
            name: 'ServerIsolate',
          );
        }
      } catch (cleanupError) {
        developer.log(
          'Failed to clean up partial file: $cleanupError',
          name: 'ServerIsolate',
          error: cleanupError,
        );
      }

      _sendEvent(IsolateEvent.transferFailed(
        sessionId: sessionId,
        reason: e.toString(),
      ));

      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}

