/// Contract for ServerController (AsyncNotifier)
///
/// This interface defines the public API for the file transfer server controller.
/// Implementation will use @riverpod annotation.

// ignore_for_file: unused_element

/// State exposed by the controller
abstract class _ServerState {
  /// Whether the HTTP server is currently running
  bool get isRunning;

  /// Port the server is bound to (null if not running)
  int? get port;

  /// Whether discovery broadcast is active
  bool get isBroadcasting;

  /// Current active transfer session (null if idle)
  _TransferSession? get activeSession;

  /// Progress of active transfer (null if idle)
  _TransferProgress? get transferProgress;

  /// Last error message (null if no error)
  String? get error;
}

/// Active transfer session
abstract class _TransferSession {
  String get sessionId;
  _TransferMetadata get metadata;
  DateTime get createdAt;
  _SessionStatus get status;
}

/// Transfer metadata from handshake
abstract class _TransferMetadata {
  String get fileName;
  int get fileSize;
  String get fileType;
  String get checksum;
  bool get isFolder;
  int get fileCount;
  String get senderDeviceId;
  String get senderAlias;
}

/// Session status enum
enum _SessionStatus { pending, receiving, completed, failed, expired }

/// Transfer progress
abstract class _TransferProgress {
  int get bytesReceived;
  int get totalBytes;
  DateTime get startedAt;
  int get percentComplete;
}

/// Controller public methods
abstract class _ServerControllerContract {
  /// Starts the HTTP server and discovery broadcast.
  ///
  /// - Binds server to available port
  /// - Attempts to start discovery broadcast
  /// - If broadcast fails, logs warning and continues
  ///
  /// Throws if server fails to start.
  Future<void> startServer();

  /// Stops the HTTP server and discovery broadcast.
  ///
  /// - Cancels any active transfer
  /// - Stops discovery broadcast (if active)
  /// - Unbinds server port
  Future<void> stopServer();

  /// Toggles server state (convenience method).
  ///
  /// Calls [startServer] if stopped, [stopServer] if running.
  Future<void> toggleServer();

  /// Clears the last error message.
  void clearError();
}

/// FileServerService contract (HTTP handling)
abstract class _FileServerServiceContract {
  /// Starts the shelf HTTP server on given port.
  ///
  /// Returns the actual bound port (useful if port=0 for auto-assign).
  Future<int> start({int port = 0});

  /// Stops the HTTP server.
  Future<void> stop();

  /// Whether server is currently running.
  bool get isRunning;

  /// Current bound port (null if not running).
  int? get port;

  /// Stream of transfer events (for controller to subscribe).
  Stream<_TransferEvent> get events;
}

/// Events emitted by FileServerService
sealed class _TransferEvent {}

class _HandshakeReceivedEvent extends _TransferEvent {
  final _TransferMetadata metadata;
  _HandshakeReceivedEvent(this.metadata);
}

class _HandshakeAcceptedEvent extends _TransferEvent {
  final String sessionId;
  _HandshakeAcceptedEvent(this.sessionId);
}

class _HandshakeRejectedEvent extends _TransferEvent {
  final String reason;
  _HandshakeRejectedEvent(this.reason);
}

class _UploadStartedEvent extends _TransferEvent {
  final String sessionId;
  _UploadStartedEvent(this.sessionId);
}

class _UploadProgressEvent extends _TransferEvent {
  final int bytesReceived;
  final int totalBytes;
  _UploadProgressEvent(this.bytesReceived, this.totalBytes);
}

class _UploadCompletedEvent extends _TransferEvent {
  final String savedPath;
  final bool checksumVerified;
  _UploadCompletedEvent(this.savedPath, this.checksumVerified);
}

class _UploadFailedEvent extends _TransferEvent {
  final String reason;
  _UploadFailedEvent(this.reason);
}

/// FileStorageService contract (file system operations)
abstract class _FileStorageServiceContract {
  /// Gets the default receive folder path.
  Future<String> getReceiveFolder();

  /// Resolves filename collisions by appending numeric suffix.
  Future<String> resolveFilename(String folder, String filename);

  /// Writes a stream of bytes to file, returns final path.
  Future<String> writeStream(String path, Stream<List<int>> data);

  /// Deletes a file (for cleanup on failure).
  Future<void> deleteFile(String path);

  /// Extracts ZIP archive to folder, preserving structure.
  Future<void> extractZip(String zipPath, String targetFolder);

  /// Gets available storage space in bytes.
  Future<int> getAvailableSpace();
}

