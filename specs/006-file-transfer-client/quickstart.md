# Quickstart: File Transfer Client (Send Logic)

**Feature**: 006-file-transfer-client | **Date**: 2025-12-06

## Prerequisites

1. Feature 004 (Device Discovery) implemented - provides `Device` model
2. Feature 005 (File Transfer Server) implemented - receiver API
3. Feature 003 (History) implemented - `HistoryRepository` for logging

## Dependencies to Add

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.0.0
  file_picker: ^8.0.0
  # Already present: archive, crypto, flutter_riverpod, freezed
```

## Implementation Order

### Phase 1: Domain Models (Estimated: 1 hour)

1. Create `lib/src/features/send/domain/selected_item_type.dart`
2. Create `lib/src/features/send/domain/selected_item.dart` (freezed)
3. Create `lib/src/features/send/domain/transfer_payload.dart` (freezed)
4. Create `lib/src/features/send/domain/transfer_result.dart` (freezed)
5. Create `lib/src/features/send/domain/transfer_state.dart` (freezed union)
6. Run `dart run build_runner build`

### Phase 2: Data Services (Estimated: 3 hours)

1. Create `lib/src/features/send/data/file_picker_service.dart`
   - `pickFiles()` - multi-select files
   - `pickFolder()` - single folder
   
2. Create `lib/src/features/send/data/compression_service.dart`
   - `compressFolder(path)` - returns temp ZIP path
   - `computeChecksum(path)` - returns MD5
   - `cleanup(path)` - delete temp file

3. Create `lib/src/features/send/data/transfer_client_service.dart`
   - `handshake(device, metadata)` - POST /api/v1/info
   - `upload(device, sessionId, path, onProgress, cancelToken)` - POST /api/v1/upload

### Phase 3: Application Controllers (Estimated: 3 hours)

1. Create `lib/src/features/send/application/file_selection_controller.dart`
   - State: `List<SelectedItem>`
   - Actions: `pickFiles()`, `pickFolder()`, `pasteText(text)`, `removeItem(id)`, `clear()`

2. Create `lib/src/features/send/application/transfer_controller.dart`
   - State: `TransferState`
   - Actions: `send(device, items)`, `cancel()`, `retry(failedItems)`
   - Integrates: CompressionService, TransferClientService, HistoryRepository

### Phase 4: Tests (Estimated: 2 hours)

1. Unit test CompressionService (ZIP creation, checksum)
2. Unit test TransferClientService (mock dio responses)
3. Unit test FileSelectionController (state management)
4. Unit test TransferController (full flow with mocks)

## Key Integration Points

### Device Selection (from Discovery)

```dart
// Get selected device from discovery controller
final device = ref.watch(selectedDeviceProvider);
```

### History Recording

```dart
// Record transfer in history
final entry = NewTransferHistoryEntry(
  transferId: sessionId,
  fileName: payload.fileName,
  fileCount: payload.fileCount,
  totalSize: payload.fileSize,
  fileType: payload.fileType,
  status: success ? TransferStatus.completed : TransferStatus.failed,
  direction: TransferDirection.sent,
  remoteDeviceAlias: device.alias,
);
await ref.read(historyRepositoryProvider).addEntry(entry);
```

## Testing the Feature

### Manual Test Flow

1. Start receiver (Feature 005) on Device B
2. Start discovery on Device A
3. Select Device B as target
4. Pick files/folder
5. Tap Send
6. Verify progress updates
7. Verify file arrives on Device B
8. Verify history entry created on both devices

### Unit Test Command

```bash
fvm flutter test test/features/send/
```

