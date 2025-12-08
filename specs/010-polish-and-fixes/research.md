# Research: Polish and Bug Fixes

**Feature**: 010-polish-and-fixes | **Date**: 2025-12-07

## Overview

This document captures research findings for the 8 polish items and bug fixes. Since this feature is primarily bug fixes and UI polish, research focuses on root cause analysis and implementation patterns.

---

## Issue 1: Server Isolate Stream Close Error

**Error**: `[ServerIsolateManager] Failed to parse event: Bad state: Cannot add new events after calling close`

### Root Cause Analysis

**Location**: `lib/src/features/receive/data/server_isolate_manager.dart`

The `_eventController` (StreamController) is being closed in `dispose()` or `_cleanup()`, but events continue to arrive from the isolate after the controller is closed.

**Code Path**:
1. `ServerIsolateManager.dispose()` calls `_cleanup()` or `_cleanupWithoutKill()`
2. `_cleanup()` closes `_eventController`
3. Isolate may still send events via `_receivePort` before fully terminating
4. `_handleIsolateMessage()` tries to add to closed controller → Error

### Solution

1. Add a `_disposed` flag to guard against adding events after close
2. Cancel `_receivePort` subscription before closing controller
3. Use `_eventController.isClosed` check before adding events

---

## Issue 2: Server Isolate Handshake Timeout

**Error**: Handshake timeout errors during server startup

### Root Cause Analysis

**Location**: `lib/src/features/receive/data/server_isolate_manager.dart` (lines 138-150)

The handshake timeout is set to 10 seconds, which may be insufficient on slower devices or when the system is under load.

**Current Code**:
```dart
final sendPort = await _receivePort.first.timeout(
  const Duration(seconds: 10),
  onTimeout: () => throw TimeoutException('Handshake timeout'),
);
```

### Solution

1. Increase timeout to 30 seconds
2. Add retry logic (up to 3 attempts) with exponential backoff
3. Log detailed diagnostics on timeout for debugging

---

## Issue 3: Port 8080 Always Showing in IdentityCard

**Bug**: IdentityCard shows port 8080 instead of actual server port (53318)

### Root Cause Analysis

**Location**: 
- `lib/src/core/providers/device_info_provider.dart` - defines `kDefaultPort = 8080`
- `lib/src/features/receive/application/device_identity_provider.dart` - uses `deviceInfoProvider.getPort()` which returns `kDefaultPort`
- `lib/src/features/receive/presentation/widgets/identity_card.dart` - displays `identity.port`

The `DeviceIdentity` is created with `kDefaultPort` (8080) but the actual server runs on port 53318 (hardcoded in `ServerController`).

### Solution

1. Pass actual port from `ServerState` to `IdentityCard` widget
2. Update `IdentityCard` to accept optional port override parameter
3. When server is running, use `ServerState.port`; otherwise show "Not running"

---

## Issue 4: Send History Not Working

### Root Cause Analysis

**Location**: `lib/src/features/send/application/transfer_controller.dart` (lines 485-506)

The `_recordHistory()` method exists and appears correct:
```dart
Future<void> _recordHistory(TransferResult result) async {
  await _historyRepository.addEntry(TransferHistoryEntry(
    // ... fields
    direction: TransferDirection.sent,
  ));
}
```

**Potential Issues**:
1. Method may not be called on all completion paths
2. Exception in `_recordHistory()` may be swallowed
3. Database write may fail silently

### Investigation Steps

1. Add logging to `_recordHistory()` to confirm it's called
2. Check if `TransferDirection.sent` filter works in history query
3. Verify database table has `direction` column populated

---

## Issue 5: Device Discovery Disappearing

### Root Cause Analysis

**Location**: `lib/src/features/discovery/application/discovery_controller.dart`

The `_stalenessTimer` and `_pruneStaleDevices()` method remove devices that haven't been seen recently. The current timeout may be too aggressive.

**Current Behavior**:
- Devices are pruned based on `_stalenessTimeout`
- mDNS announcements may not be frequent enough

### Solution

1. Increase `_stalenessTimeout` to 2 minutes (120 seconds)
2. Add periodic liveness checks (ping discovered devices every 30-60 seconds)
3. Only remove devices after confirming they're truly offline

---

## Issue 6: Storage Permission (Android)

### Research

**Android Storage Permission Model**:
- API < 23: Permissions granted at install time
- API 23-28: Runtime permissions required (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`)
- API 29+: Scoped storage - app can write to Downloads without permission
- API 30+: `MANAGE_EXTERNAL_STORAGE` for full access (requires Play Store justification)

**Current State**:
- `AndroidManifest.xml` declares permissions but doesn't request at runtime
- `FileStorageService` writes to `/storage/emulated/0/Download` which requires permission on API 23-28

### Solution

1. Add `permission_handler` package
2. Create `PermissionProvider` to check/request storage permission
3. Request permission before first file save
4. Handle denial gracefully with user-friendly message

---

## Issue 7: Accept/Decline UI (Bottom Sheet)

### Design Pattern

Based on clarification: Use bottom sheet overlay for accept/decline prompts.

**Implementation**:
1. Create `PendingRequestSheet` widget
2. Show when `ServerState.pendingRequest` is not null
3. Display: sender name, file name, file size, accept/decline buttons
4. 30-second auto-decline timeout with countdown
5. Dismiss on accept/decline/timeout

---

## Issue 8: Transfer Progress UI (Status Bar)

### Design Pattern

Based on clarification: Use dedicated status bar for transfer progress.

**Implementation**:
1. Create `TransferStatusBar` widget (fixed at top or bottom of screen)
2. Show during active transfer on both Send and Receive screens
3. Display: file name, progress bar, percentage, bytes transferred
4. Animate in/out based on transfer state

---

## Dependencies to Add

| Package | Version | Purpose |
|---------|---------|---------|
| `permission_handler` | ^11.0.0 | Android runtime permission requests |

---

## Files to Modify

| File | Changes |
|------|---------|
| `server_isolate_manager.dart` | Fix stream lifecycle, increase timeout |
| `discovery_controller.dart` | Increase staleness timeout to 2 min |
| `device_identity_provider.dart` | Accept port from ServerState |
| `identity_card.dart` | Display actual port |
| `receive_screen.dart` | Add status bar, bottom sheet, toasts |
| `send_screen.dart` | Add status bar, toasts |
| `transfer_controller.dart` | Debug/fix history recording |
| `pubspec.yaml` | Add permission_handler |
| `AndroidManifest.xml` | Already has permissions declared |

## New Files to Create

| File | Purpose |
|------|---------|
| `lib/src/core/providers/permission_provider.dart` | Storage permission handling |
| `lib/src/core/widgets/transfer_status_bar.dart` | Progress display widget |
| `lib/src/features/receive/presentation/widgets/pending_request_sheet.dart` | Accept/decline bottom sheet |

