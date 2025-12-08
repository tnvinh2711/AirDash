# Research: File Transfer Server (Receive Logic)

**Feature**: 005-file-transfer-server | **Date**: 2025-12-06

## 1. HTTP Server Framework (shelf + shelf_router)

**Decision**: Use `shelf ^1.4.0` and `shelf_router ^1.1.0`

**Rationale**:
- Constitution mandates `shelf` for HTTP server receiver
- Lightweight, composable middleware architecture
- Supports streaming request bodies (essential for large file uploads)
- `shelf_router` provides clean route definition for REST endpoints
- Cross-platform support (works on all Flutter targets)

**Alternatives Considered**:
- `dart:io` HttpServer directly: Lower-level, more boilerplate
- `alfred`: Not mandated by constitution
- `conduit`: Too heavy for this use case

**API Pattern**:
```dart
// Create router
final router = Router();
router.post('/api/v1/info', _handleHandshake);
router.post('/api/v1/upload', _handleUpload);

// Start server
final handler = Pipeline().addMiddleware(logRequests()).addHandler(router.call);
final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
```

---

## 2. File Streaming Strategy

**Decision**: Use shelf's `Request.read()` stream for incremental file writes

**Rationale**:
- `Request.read()` returns `Stream<List<int>>` - memory efficient for large files
- Can compute checksum incrementally while receiving
- Supports cancellation via stream subscription
- Avoids loading entire file into memory (critical for 1GB+ files)

**Implementation Pattern**:
```dart
Future<Response> handleUpload(Request request) async {
  final file = File(targetPath).openWrite();
  final digest = md5.startChunkedConversion(...);
  
  await for (final chunk in request.read()) {
    file.add(chunk);
    digest.add(chunk);
  }
  
  await file.close();
  final checksum = digest.close();
  // Verify checksum...
}
```

---

## 3. Checksum Algorithm

**Decision**: Use MD5 via `crypto ^3.0.0` package

**Rationale**:
- Fast computation suitable for large files
- Widely supported across platforms
- Good enough for integrity verification (not cryptographic security)
- `crypto` package is pure Dart, works everywhere

**Alternatives Considered**:
- SHA-256: Slower, overkill for LAN transfer integrity
- CRC32: Faster but weaker collision resistance
- SHA-1: Deprecated for security, no benefit over MD5 for this use case

---

## 4. ZIP Extraction (Folder Transfers)

**Decision**: Use `archive ^3.4.0` package

**Rationale**:
- Pure Dart implementation (cross-platform)
- Supports streaming decompression
- Can extract while preserving directory structure
- Well-maintained, widely used

**Implementation Pattern**:
```dart
final archive = ZipDecoder().decodeBuffer(InputStream(bytes));
for (final file in archive) {
  if (file.isFile) {
    final outputFile = File('$extractPath/${file.name}');
    outputFile.createSync(recursive: true);
    outputFile.writeAsBytesSync(file.content as List<int>);
  }
}
```

---

## 5. Session Management

**Decision**: UUID-based session tokens with 5-minute timeout

**Rationale**:
- Session ID returned in handshake response
- Upload must include session ID in header (`X-Transfer-Session`)
- Simple Map storage (single concurrent transfer)
- Timer-based cleanup for abandoned sessions

**Implementation Pattern**:
```dart
class TransferSession {
  final String sessionId;
  final TransferMetadata metadata;
  final DateTime createdAt;
  Timer? timeoutTimer;
  
  bool get isExpired => DateTime.now().difference(createdAt) > Duration(minutes: 5);
}
```

---

## 6. Discovery Integration

**Decision**: Inject `DiscoveryController` reference; call startBroadcast/stopBroadcast

**Rationale**:
- Existing Spec 04 provides `DiscoveryController.startBroadcast(LocalDeviceInfo)`
- Server needs to pass port in `LocalDeviceInfo` for broadcast
- If broadcast fails, log warning but continue server start (per clarification)

**Integration Pattern**:
```dart
Future<void> startServer() async {
  // Start HTTP server first
  _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  
  // Attempt discovery broadcast
  try {
    await ref.read(discoveryControllerProvider.notifier).startBroadcast(
      LocalDeviceInfo(alias: deviceAlias, port: _server.port, ...),
    );
  } catch (e) {
    // Log warning, server continues
  }
}
```

---

## 7. History Integration

**Decision**: Use existing `HistoryRepository.addEntry()` with `TransferDirection.received`

**Rationale**:
- Existing Spec 03 provides `NewTransferHistoryEntry` DTO
- Call on successful completion or failure
- Use `TransferDirection.received` enum value

---

## 8. File Naming Collision

**Decision**: Append numeric suffix `(1)`, `(2)`, etc.

**Rationale**:
- Common pattern (macOS, Windows behavior)
- Check existence before writing, increment until unique
- Preserve original extension

**Implementation**:
```dart
String resolveCollision(String path) {
  var file = File(path);
  var counter = 1;
  while (file.existsSync()) {
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    file = File('${p.dirname(path)}/$name ($counter)$ext');
    counter++;
  }
  return file.path;
}
```

