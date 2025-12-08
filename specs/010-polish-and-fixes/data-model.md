# Data Model: Polish and Bug Fixes

**Feature**: 010-polish-and-fixes | **Date**: 2025-12-07

## Overview

This feature primarily fixes bugs and adds UI polish. Most data models already exist. This document describes new/modified models and state objects.

---

## Existing Models (No Changes)

These models are already defined and work correctly:

| Model | Location | Purpose |
|-------|----------|---------|
| `TransferHistoryEntry` | `lib/src/features/history/domain/transfer_history_entry.dart` | History record |
| `TransferProgress` | `lib/src/features/receive/domain/transfer_progress.dart` | Progress tracking |
| `TransferMetadata` | `lib/src/features/receive/domain/transfer_metadata.dart` | File metadata |
| `ServerState` | `lib/src/features/receive/domain/server_state.dart` | Server status |
| `DiscoveredDevice` | `lib/src/features/discovery/domain/discovered_device.dart` | Peer device |
| `DeviceIdentity` | `lib/src/features/receive/domain/device_identity.dart` | Local device info |

---

## Modified Models

### DeviceIdentity (Enhancement)

**File**: `lib/src/features/receive/domain/device_identity.dart`

The `port` field should reflect the actual server port, not the default.

```dart
@freezed
class DeviceIdentity with _$DeviceIdentity {
  const factory DeviceIdentity({
    required String alias,
    required DeviceType deviceType,
    required String os,
    String? ipAddress,
    int? port,  // Now nullable - null when server not running
  }) = _DeviceIdentity;
}
```

**Change**: Make `port` nullable to indicate server not running state.

---

## New State Objects

### PendingTransferRequest

**Purpose**: Represents an incoming transfer request awaiting user decision.

**File**: `lib/src/features/receive/domain/pending_transfer_request.dart`

```dart
@freezed
class PendingTransferRequest with _$PendingTransferRequest {
  const factory PendingTransferRequest({
    required String requestId,
    required String senderAlias,
    required String senderDeviceId,
    required String fileName,
    required int fileSize,
    required String fileType,
    required bool isFolder,
    required int fileCount,
    required DateTime receivedAt,
  }) = _PendingTransferRequest;
}
```

**Fields**:
- `requestId`: Unique identifier for this request
- `senderAlias`: Human-readable sender name
- `senderDeviceId`: mDNS device ID of sender
- `fileName`: Name of file/folder being sent
- `fileSize`: Total size in bytes
- `fileType`: MIME type
- `isFolder`: True if sending a folder (ZIP)
- `fileCount`: Number of files (1 for single file)
- `receivedAt`: Timestamp for timeout calculation

---

### TransferStatusBarState

**Purpose**: State for the dedicated transfer status bar widget.

**File**: `lib/src/core/widgets/transfer_status_bar.dart` (inline)

```dart
@freezed
class TransferStatusBarState with _$TransferStatusBarState {
  const factory TransferStatusBarState({
    required bool isVisible,
    required bool isSending,  // true = sending, false = receiving
    required String fileName,
    required int bytesTransferred,
    required int totalBytes,
    required double progress,  // 0.0 to 1.0
    String? peerName,
  }) = _TransferStatusBarState;
  
  factory TransferStatusBarState.hidden() => const TransferStatusBarState(
    isVisible: false,
    isSending: false,
    fileName: '',
    bytesTransferred: 0,
    totalBytes: 0,
    progress: 0,
  );
}
```

---

## State Provider Updates

### ServerState Enhancement

**File**: `lib/src/features/receive/domain/server_state.dart`

Add `pendingRequest` field to track incoming requests:

```dart
@freezed
class ServerState with _$ServerState {
  const factory ServerState({
    required bool isRunning,
    required int port,
    // ... existing fields
    PendingTransferRequest? pendingRequest,  // NEW
    DateTime? pendingRequestTimeout,          // NEW
  }) = _ServerState;
}
```

---

## Database Schema (No Changes)

The existing `transfer_history` table already supports both sent and received transfers via the `direction` column:

```sql
CREATE TABLE transfer_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  direction TEXT NOT NULL,  -- 'sent' or 'received'
  peer_name TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  status TEXT NOT NULL,
  saved_path TEXT
);
```

No schema changes required.

---

## Provider Dependencies

```
deviceIdentityProvider
  └── depends on: deviceInfoProviderProvider
  └── NEW: also reads serverControllerProvider.port when available

serverControllerProvider
  └── manages: ServerState (with new pendingRequest field)
  └── emits: IsolateEvent for pending requests

transferStatusBarProvider (NEW)
  └── watches: serverControllerProvider (for receive progress)
  └── watches: transferControllerProvider (for send progress)
  └── emits: TransferStatusBarState
```

---

## Summary

| Category | Count | Notes |
|----------|-------|-------|
| New Models | 2 | PendingTransferRequest, TransferStatusBarState |
| Modified Models | 2 | DeviceIdentity (nullable port), ServerState (pending request) |
| Database Changes | 0 | Existing schema sufficient |
| New Providers | 1 | transferStatusBarProvider |

