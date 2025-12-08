# Data Model: File Transfer Client (Send Logic)

**Feature**: 006-file-transfer-client | **Date**: 2025-12-06

## Entity Definitions

### SelectedItemType (Enum)

Type discriminator for items in selection queue.

| Value | Description |
|-------|-------------|
| `file` | Single file from file system |
| `folder` | Directory (will be compressed to ZIP) |
| `text` | Pasted text content |

---

### SelectedItem (Freezed)

An item in the selection queue awaiting transfer.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `String` | Not Null, UUID | Unique identifier for this selection |
| `type` | `SelectedItemType` | Not Null | Type discriminator |
| `path` | `String?` | Nullable | File/folder path (null for text) |
| `content` | `String?` | Nullable | Text content (null for file/folder) |
| `displayName` | `String` | Not Null | Human-readable name |
| `sizeEstimate` | `int` | Not Null, >= 0 | Size in bytes (estimate for folders) |

**Validation Rules**:
- If `type == file` or `type == folder`, `path` MUST NOT be null
- If `type == text`, `content` MUST NOT be null
- `displayName` derived from filename or "Pasted Text - [timestamp]"

---

### TransferPayload (Freezed)

Prepared data ready for transfer (after compression/checksum).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `selectedItem` | `SelectedItem` | Not Null | Original selection reference |
| `sourcePath` | `String` | Not Null | Path to file to upload (may be temp ZIP) |
| `fileName` | `String` | Not Null | Filename for receiver |
| `fileSize` | `int` | Not Null, > 0 | Size in bytes |
| `fileType` | `String` | Not Null | MIME type or extension |
| `checksum` | `String` | Not Null | MD5 hash |
| `isFolder` | `bool` | Not Null | True if compressed folder |
| `fileCount` | `int` | Not Null, >= 1 | Number of files (1 for single file/text) |
| `isTempFile` | `bool` | Not Null | True if sourcePath is temp file to cleanup |

---

### TransferResult (Freezed)

Outcome of a single item transfer attempt.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `selectedItem` | `SelectedItem` | Not Null | Which item was transferred |
| `success` | `bool` | Not Null | Whether transfer succeeded |
| `error` | `String?` | Nullable | Error message if failed |
| `savedPath` | `String?` | Nullable | Path on receiver (if success) |

---

### TransferProgress (Freezed)

Progress tracking for active transfer.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `currentItemIndex` | `int` | Not Null, >= 0 | Index in multi-item queue (0-based) |
| `totalItems` | `int` | Not Null, >= 1 | Total items in queue |
| `bytesSent` | `int` | Not Null, >= 0 | Bytes sent for current item |
| `totalBytes` | `int` | Not Null, > 0 | Total bytes for current item |
| `phase` | `TransferPhase` | Not Null | Current phase |

---

### TransferPhase (Enum)

Current phase of transfer for single item.

| Value | Description |
|-------|-------------|
| `preparing` | Computing checksum, compressing folder |
| `handshaking` | POST /api/v1/info in flight |
| `uploading` | POST /api/v1/upload streaming |
| `verifying` | Waiting for server confirmation |

---

### TransferState (Freezed Union)

Overall state of the transfer controller.

| Variant | Fields | Description |
|---------|--------|-------------|
| `idle` | - | No transfer in progress |
| `preparing` | `currentItem: SelectedItem` | Preparing payload |
| `sending` | `progress: TransferProgress, results: List<TransferResult>` | Actively transferring |
| `completed` | `results: List<TransferResult>` | All items succeeded |
| `partialSuccess` | `results: List<TransferResult>` | Some items failed |
| `failed` | `error: String, results: List<TransferResult>` | Critical failure (e.g., no network) |
| `cancelled` | `results: List<TransferResult>` | User cancelled |

---

## State Transitions

```
idle ──[startTransfer]──> preparing
preparing ──[payloadReady]──> sending
sending ──[itemComplete + more items]──> preparing (next item)
sending ──[itemComplete + no more items + all success]──> completed
sending ──[itemComplete + no more items + some failed]──> partialSuccess
sending ──[criticalError]──> failed
sending ──[cancel]──> cancelled
preparing ──[cancel]──> cancelled
any ──[reset]──> idle
```

---

## Relationships

```
Device (from discovery)
    │
    └──< TransferController.targetDevice (1:1 per transfer)

SelectedItem
    │
    ├──< FileSelectionController.items (0..N in selection)
    │
    └──< TransferPayload.selectedItem (1:1 when prepared)
    │
    └──< TransferResult.selectedItem (1:1 when complete)

HistoryRepository (from history feature)
    │
    └──< TransferController records via NewTransferHistoryEntry
```

