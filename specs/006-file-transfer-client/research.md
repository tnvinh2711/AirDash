# Research: File Transfer Client (Send Logic)

**Feature**: 006-file-transfer-client | **Date**: 2025-12-06

## 1. HTTP Client (dio)

**Decision**: Use `dio ^5.0.0`

**Rationale**:
- User explicitly requested `dio` in feature specification
- Superior streaming upload support with `onSendProgress` callback
- Built-in `CancelToken` for request cancellation (critical for cancel feature)
- Widely adopted in Flutter community for file uploads
- Cross-platform (all Flutter targets)

**Alternatives Considered**:
- `chopper`: Constitution default, but requires code generation and more boilerplate
- `http`: Too low-level for streaming uploads with progress
- Raw `dart:io` HttpClient: No progress callbacks, more complex

**Usage Pattern**:
```dart
final dio = Dio();
final cancelToken = CancelToken();

await dio.post(
  'http://$ip:$port/api/v1/upload',
  data: file.openRead(),
  options: Options(
    headers: {
      'Content-Type': 'application/octet-stream',
      'X-Transfer-Session': sessionId,
      'Content-Length': fileSize,
    },
  ),
  onSendProgress: (sent, total) {
    // Update progress state
  },
  cancelToken: cancelToken,
);
```

---

## 2. File/Folder Selection (file_picker)

**Decision**: Use `file_picker ^8.0.0`

**Rationale**:
- Cross-platform file and folder selection (Android, iOS, macOS, Windows, Linux)
- Supports multi-select for files
- Returns file paths (not just names) - essential for reading content
- Well-maintained, widely used

**Alternatives Considered**:
- Platform-specific implementations: More code, inconsistent APIs
- `flutter_file_dialog`: Less cross-platform support

**Usage Pattern**:
```dart
// Multi-select files
final result = await FilePicker.platform.pickFiles(
  allowMultiple: true,
  type: FileType.any,
);

// Select folder
final folder = await FilePicker.platform.getDirectoryPath();
```

---

## 3. ZIP Compression (archive)

**Decision**: Use `archive ^3.4.0` (same as receiver)

**Rationale**:
- Pure Dart implementation (cross-platform)
- Consistent with receiver's extraction logic
- Supports directory structure preservation
- Can handle large folders efficiently

**Usage Pattern**:
```dart
final archive = Archive();
await _addDirectoryToArchive(archive, directory, '');
final zipBytes = ZipEncoder().encode(archive);
await tempFile.writeAsBytes(zipBytes!);
```

---

## 4. Checksum Algorithm

**Decision**: Use MD5 via `crypto ^3.0.0` (same as receiver)

**Rationale**:
- Must match receiver's checksum algorithm
- Fast computation suitable for large files
- `crypto` package is pure Dart, works everywhere

**Usage Pattern**:
```dart
final digest = await md5.bind(file.openRead()).first;
final checksum = digest.toString();
```

---

## 5. Transfer Flow Architecture

**Decision**: Sequential transfer with per-item handshake/upload cycle

**Rationale**:
- Clarification Q1: User chose sequential over bundled
- Simpler error handling (know exactly which item failed)
- Receiver already handles single-transfer-at-a-time (Spec 005)
- Natural progress tracking per item

**Flow**:
```
For each SelectedItem in queue:
  1. Prepare (compress if folder, compute checksum)
  2. Handshake (POST /api/v1/info)
  3. Upload (POST /api/v1/upload with streaming)
  4. Record history
  5. Continue to next item (even if failed)
Report summary (X of Y succeeded)
```

---

## 6. Cancellation Strategy

**Decision**: CancelToken + cleanup

**Rationale**:
- Clarification Q2: User chose cancel with cleanup
- dio's CancelToken provides clean abort mechanism
- Temp files cleaned up on cancel
- State returns to Idle

**Implementation**:
```dart
class TransferController {
  CancelToken? _cancelToken;
  
  Future<void> cancel() async {
    _cancelToken?.cancel();
    await _cleanupTempFiles();
    state = TransferState.idle();
  }
}
```

---

## 7. Partial Failure Handling

**Decision**: Continue with remaining items, report partial success

**Rationale**:
- Clarification Q4: User chose continue on failure
- Better UX than stopping entirely
- Track per-item outcomes for retry capability

**State Model**:
```dart
@freezed
class TransferState with _$TransferState {
  const factory TransferState.sending({
    required int currentIndex,
    required int totalItems,
    required int bytesSent,
    required int totalBytes,
    required List<TransferResult> completedResults,
  }) = SendingState;
  
  const factory TransferState.partialSuccess({
    required List<TransferResult> results,
  }) = PartialSuccessState;
}
```

