# Research: Server Background Isolate Refactor

**Date**: 2025-12-07  
**Feature**: 009-server-background-isolate

## Research Tasks

### 1. Dart Isolate Communication Patterns

**Question**: What is the best pattern for bidirectional communication between main and server isolate?

**Decision**: Use SendPort/ReceivePort pair with a dedicated message protocol.

**Rationale**:
- Isolates cannot share memory; all communication must be via message passing
- SendPort can be sent through ReceivePort to establish bidirectional channel
- Dart's `Isolate.spawn()` is preferred over `Isolate.spawnUri()` for type safety
- Messages must be primitive types, Lists, Maps, or special transferable types (SendPort)

**Alternatives Considered**:
- `compute()` function: Too simple, single request-response, no streaming
- `IsolateChannel` from `package:stream_channel`: Adds dependency, overkill for our needs
- Manual JSON serialization: Error-prone, use Freezed for type safety instead

**Implementation Pattern**:
```dart
// Main isolate creates ReceivePort, sends its SendPort to server isolate
final mainReceivePort = ReceivePort();
await Isolate.spawn(_serverEntry, mainReceivePort.sendPort);
// Server isolate sends back its SendPort as first message
final serverSendPort = await mainReceivePort.first as SendPort;
// Now both can communicate bidirectionally
```

### 2. Isolate-Safe Message Types

**Question**: How should IsolateCommand and IsolateEvent be structured for safe transmission?

**Decision**: Use Freezed sealed classes with `toJson()`/`fromJson()` for serialization, but send as Maps directly (Dart allows Map transmission between isolates).

**Rationale**:
- Freezed provides type-safe union types with pattern matching
- Maps are isolate-transferable; JSON strings are unnecessary overhead
- Union types ensure compile-time exhaustive handling

**Alternatives Considered**:
- Raw enums + data classes: Less type-safe, manual serialization
- Protobuf: Overkill, adds complex dependency
- Plain Dart classes: No union type benefits

**Message Types**:
```dart
// Commands (Main → Server)
sealed class IsolateCommand {
  StartServer(IsolateConfig config)
  StopServer()
  RespondHandshake(String sessionId, bool accepted)
}

// Events (Server → Main)
sealed class IsolateEvent {
  ServerStarted(int port)
  ServerStopped()
  ServerError(String message)
  IncomingRequest(TransferMetadata metadata, String requestId)
  TransferProgress(String sessionId, int bytesReceived, int totalBytes)
  TransferCompleted(String sessionId, String savedPath)
  TransferFailed(String sessionId, String reason)
}
```

### 3. Deferred Handshake Response

**Question**: How should the isolate wait for user accept/reject decision?

**Decision**: Use Completer pattern with request ID tracking.

**Rationale**:
- HTTP request handler cannot block synchronously
- Store Completer in Map keyed by requestId
- When RespondHandshake command arrives, complete the Completer
- Timeout after 60 seconds with automatic rejection

**Implementation Pattern**:
```dart
final _pendingRequests = <String, Completer<bool>>{};

Future<Response> handleHandshake(Request request) async {
  final requestId = Uuid().v4();
  final completer = Completer<bool>();
  _pendingRequests[requestId] = completer;
  
  // Send to main isolate for user decision
  sendPort.send(IncomingRequest(metadata, requestId).toMap());
  
  // Wait for response (with timeout)
  final accepted = await completer.future.timeout(
    Duration(seconds: 60),
    onTimeout: () => false,
  );
  
  _pendingRequests.remove(requestId);
  return accepted ? Response.ok(...) : Response(403, ...);
}
```

### 4. Progress Throttling Strategy

**Question**: How to limit progress updates to 10/second without losing accuracy?

**Decision**: Use time-based throttling with last-sent timestamp.

**Rationale**:
- Simple and efficient
- Guarantees final update is always sent
- 100ms minimum interval = 10 updates/second max

**Implementation Pattern**:
```dart
DateTime? _lastProgressSent;
int _lastBytesReported = 0;

void reportProgress(int bytes, int total) {
  final now = DateTime.now();
  if (_lastProgressSent == null || 
      now.difference(_lastProgressSent!).inMilliseconds >= 100 ||
      bytes == total) {
    sendPort.send(TransferProgress(sessionId, bytes, total).toMap());
    _lastProgressSent = now;
    _lastBytesReported = bytes;
  }
}
```

### 5. Settings Passing to Isolate

**Question**: What settings snapshot should be passed at startup?

**Decision**: Pass IsolateConfig with quickSaveEnabled, destinationPath, and port.

**Rationale**:
- Isolate needs destination path for file writes
- Quick Save flag determines auto-accept behavior
- Port is needed for server binding
- Receive Mode is checked before starting (not needed in isolate)

**IsolateConfig Structure**:
```dart
@freezed
class IsolateConfig with _$IsolateConfig {
  const factory IsolateConfig({
    required int port,
    required String destinationPath,
    required bool quickSaveEnabled,
  }) = _IsolateConfig;
}
```

## Summary

All NEEDS CLARIFICATION items resolved. Ready for Phase 1 design.

