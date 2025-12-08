import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/history/application/history_provider.dart';
import 'package:flux/src/features/history/domain/new_transfer_history_entry.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';
import 'package:flux/src/features/receive/data/file_storage_service.dart';
import 'package:flux/src/features/receive/data/server_isolate_manager.dart';
import 'package:flux/src/features/receive/domain/session_status.dart';
import 'package:flux/src/features/receive/domain/transfer_event.dart';
import 'package:flux/src/features/receive/domain/transfer_metadata.dart';
import 'package:flux/src/features/receive/domain/transfer_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

part 'file_server_service.g.dart';

/// HTTP server service for receiving file transfers.
///
/// Provides REST endpoints for handshake and file upload.
class FileServerService {
  /// Creates a [FileServerService].
  FileServerService({required FileStorageService storageService, Ref? ref})
    : _storageService = storageService,
      _ref = ref;

  final FileStorageService _storageService;
  final Ref? _ref;
  final _uuid = const Uuid();
  final _eventController = StreamController<TransferEvent>.broadcast();

  HttpServer? _server;
  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _socketSubscription;
  StreamSubscription<HttpRequest>? _httpSubscription;
  TransferSession? _activeSession;
  Timer? _sessionTimer;

  // Pre-initialized handler (lazy)
  Handler? _handler;

  Handler _getHandler() {
    if (_handler != null) return _handler!;

    final router = Router()
      ..post('/api/v1/info', _handleHandshake)
      ..post('/api/v1/upload', _handleUpload);

    _handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    return _handler!;
  }

  /// Stream of transfer events.
  Stream<TransferEvent> get events => _eventController.stream;

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// The port the server is listening on, or null if not running.
  int? get port => _server?.port;

  /// Gets the active session, if any.
  TransferSession? getSession(String sessionId) {
    if (_activeSession?.sessionId == sessionId) {
      return _activeSession;
    }
    return null;
  }

  /// Pre-initializes the handler to avoid lag on first start.
  void warmUp() {
    _getHandler();
  }

  /// Starts the HTTP server on an available port.
  ///
  /// Returns the port number the server is bound to.
  /// Note: This runs in the main isolate. For production use,
  /// [ServerIsolateManager] runs the server in a background isolate.
  Future<int> start({int preferredPort = 0}) async {
    if (_server != null) {
      developer.log(
        'Server already running on port ${_server!.port}',
        name: 'FileServerService',
      );
      return _server!.port;
    }

    developer.log(
      'Starting server on port $preferredPort',
      name: 'FileServerService',
    );

    try {
      // Start HTTP server using shelf_io
      // Port 0 means use any available ephemeral port
      _server = await shelf_io.serve(
        _getHandler(),
        InternetAddress.anyIPv4,
        preferredPort,
      );

      developer.log(
        'Server started on port ${_server!.port}',
        name: 'FileServerService',
      );

      return _server!.port;
    } catch (e, stack) {
      developer.log(
        'Failed to start server: $e',
        name: 'FileServerService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Stops the HTTP server.
  Future<void> stop() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _activeSession = null;
    await _httpSubscription?.cancel();
    _httpSubscription = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _serverSocket?.close();
    _serverSocket = null;
    await _server?.close(force: true);
    _server = null;
  }

  /// Disposes resources.
  void dispose() {
    _eventController.close();
    stop();
  }

  Future<Response> _handleHandshake(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Parse and validate metadata
      final metadata = TransferMetadata.fromJson(json);
      final validationError = metadata.validate();
      if (validationError != null) {
        return Response(
          400,
          body: jsonEncode({'accepted': false, 'error': validationError}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      _eventController.add(HandshakeReceivedEvent(metadata));

      // Check if busy
      if (_activeSession != null) {
        _eventController.add(const HandshakeRejectedEvent('busy'));
        return Response(
          409,
          body: jsonEncode({'accepted': false, 'error': 'busy'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check storage space
      final availableSpace = await _storageService.getAvailableSpace();
      if (metadata.fileSize > availableSpace) {
        _eventController.add(
          const HandshakeRejectedEvent('insufficient_storage'),
        );
        return Response(
          507,
          body: jsonEncode({
            'accepted': false,
            'error': 'insufficient_storage',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create session
      final sessionId = _uuid.v4();
      final requestId = _uuid.v4();
      _activeSession = TransferSession.accepted(
        sessionId: sessionId,
        requestId: requestId,
        metadata: metadata,
      );

      // Start session timeout timer
      _startSessionTimer();

      _eventController.add(HandshakeAcceptedEvent(sessionId));

      return Response.ok(
        jsonEncode({'accepted': true, 'sessionId': sessionId}),
        headers: {'Content-Type': 'application/json'},
      );
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

    if (_activeSession == null || _activeSession!.sessionId != sessionId) {
      return Response(
        404,
        body: jsonEncode({'success': false, 'error': 'session_not_found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (_activeSession!.isExpired) {
      _clearSession();
      return Response(
        410,
        body: jsonEncode({'success': false, 'error': 'session_expired'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    _sessionTimer?.cancel();
    _activeSession = _activeSession!.copyWith(status: SessionStatus.inProgress);
    _eventController.add(UploadStartedEvent(sessionId));

    try {
      final metadata = _activeSession!.metadata;
      final folder = await _storageService.getReceiveFolder();
      final filePath = await _storageService.resolveFilename(
        folder,
        metadata.fileName,
      );

      // Stream file to disk with progress updates
      var bytesReceived = 0;
      final totalBytes = metadata.fileSize;
      final progressStream = request.read().map((chunk) {
        bytesReceived += chunk.length;
        _eventController.add(
          UploadProgressEvent(
            bytesReceived: bytesReceived,
            totalBytes: totalBytes,
          ),
        );
        return chunk;
      });

      final result = await _storageService.writeStream(
        filePath,
        progressStream,
      );

      // Verify checksum
      final checksumMatch =
          result.checksum.toLowerCase() == metadata.checksum.toLowerCase();

      if (!checksumMatch) {
        await _storageService.deleteFile(filePath);
        _eventController.add(const UploadFailedEvent('checksum_mismatch'));
        await _recordHistory(TransferStatus.failed);
        _clearSession();
        return Response(
          422,
          body: jsonEncode({'success': false, 'error': 'checksum_mismatch'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Extract ZIP if this is a folder transfer
      var finalPath = result.path;
      if (metadata.isFolder) {
        finalPath = await _storageService.extractZip(result.path);
      }

      _eventController.add(
        UploadCompletedEvent(savedPath: finalPath, checksumVerified: true),
      );
      await _recordHistory(TransferStatus.completed);
      _clearSession();

      return Response.ok(
        jsonEncode({
          'success': true,
          'savedPath': finalPath,
          'checksumVerified': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _eventController.add(UploadFailedEvent(e.toString()));
      await _recordHistory(TransferStatus.failed);
      _clearSession();
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(TransferSession.timeout, () {
      if (_activeSession != null) {
        _activeSession = _activeSession!.copyWith(
          status: SessionStatus.cancelled,
        );
        _eventController.add(const UploadFailedEvent('session_expired'));
        _clearSession();
      }
    });
  }

  void _clearSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _activeSession = null;
  }

  Future<void> _recordHistory(TransferStatus status) async {
    if (_ref == null || _activeSession == null) return;

    final metadata = _activeSession!.metadata;
    final entry = NewTransferHistoryEntry(
      transferId: _activeSession!.sessionId,
      fileName: metadata.fileName,
      fileCount: metadata.fileCount,
      totalSize: metadata.fileSize,
      fileType: metadata.fileType,
      status: status,
      direction: TransferDirection.received,
      remoteDeviceAlias: metadata.senderAlias,
    );

    try {
      final repository = _ref.read(historyRepositoryProvider);
      await repository.addEntry(entry);
    } catch (e) {
      // Log error but don't fail the transfer
    }
  }
}

/// Provides the [FileServerService] instance.
@riverpod
FileServerService fileServerService(Ref ref) {
  final storageService = ref.watch(fileStorageServiceProvider);
  final service = FileServerService(storageService: storageService, ref: ref)
    // Pre-initialize handler to avoid lag on first start
    ..warmUp();
  ref.onDispose(service.dispose);
  return service;
}
