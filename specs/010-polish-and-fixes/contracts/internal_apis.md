# Internal API Contracts: Polish and Bug Fixes

**Feature**: 010-polish-and-fixes | **Date**: 2025-12-07

## Overview

This feature does not introduce new external HTTP APIs. All changes are internal to the Flutter application. This document describes the internal provider/controller API changes.

---

## Provider API Changes

### ServerControllerProvider

**Location**: `lib/src/features/receive/application/server_controller.dart`

#### New Methods

```dart
/// Accept a pending transfer request
Future<void> acceptPendingRequest(String requestId);

/// Decline a pending transfer request
Future<void> declinePendingRequest(String requestId);
```

#### State Changes

```dart
// ServerState now includes:
PendingTransferRequest? pendingRequest;
DateTime? pendingRequestTimeout;
```

---

### DeviceIdentityProvider

**Location**: `lib/src/features/receive/application/device_identity_provider.dart`

#### Signature Change

```dart
// Before: Always returns kDefaultPort (8080)
@riverpod
Future<DeviceIdentity> deviceIdentity(Ref ref);

// After: Returns actual port from ServerState when available
@riverpod
Future<DeviceIdentity> deviceIdentity(Ref ref) {
  // ... existing logic
  final serverState = ref.watch(serverControllerProvider).valueOrNull;
  final actualPort = serverState?.isRunning == true 
      ? serverState?.port 
      : null;
  
  return DeviceIdentity(
    // ... other fields
    port: actualPort,  // null when server not running
  );
}
```

---

### DiscoveryControllerProvider

**Location**: `lib/src/features/discovery/application/discovery_controller.dart`

#### Configuration Change

```dart
// Before
static const _stalenessTimeout = Duration(seconds: 30);  // Example

// After
static const _stalenessTimeout = Duration(minutes: 2);
```

---

## New Providers

### TransferStatusBarProvider

**Location**: `lib/src/core/widgets/transfer_status_bar.dart`

```dart
@riverpod
TransferStatusBarState transferStatusBar(Ref ref) {
  // Watch both send and receive progress
  final serverState = ref.watch(serverControllerProvider).valueOrNull;
  final sendState = ref.watch(transferControllerProvider);
  
  // Return appropriate state based on active transfer
  if (serverState?.isReceiving == true) {
    return TransferStatusBarState(
      isVisible: true,
      isSending: false,
      fileName: serverState!.transferProgress!.fileName,
      // ... other fields
    );
  }
  
  if (sendState.isTransferring) {
    return TransferStatusBarState(
      isVisible: true,
      isSending: true,
      // ... other fields
    );
  }
  
  return TransferStatusBarState.hidden();
}
```

---

### PermissionProvider

**Location**: `lib/src/core/providers/permission_provider.dart`

```dart
@riverpod
class PermissionController extends _$PermissionController {
  @override
  Future<PermissionStatus> build() async {
    return _checkStoragePermission();
  }
  
  /// Check current storage permission status
  Future<PermissionStatus> _checkStoragePermission();
  
  /// Request storage permission from user
  Future<bool> requestStoragePermission();
  
  /// Check if permission is granted
  bool get isGranted;
}
```

---

## Widget Contracts

### IdentityCard

**Location**: `lib/src/features/receive/presentation/widgets/identity_card.dart`

```dart
class IdentityCard extends ConsumerWidget {
  const IdentityCard({
    required this.isReceiving,
    this.actualPort,  // NEW: Override port display
    super.key,
  });

  final bool isReceiving;
  final int? actualPort;  // NEW
}
```

---

### PendingRequestSheet

**Location**: `lib/src/features/receive/presentation/widgets/pending_request_sheet.dart`

```dart
class PendingRequestSheet extends ConsumerWidget {
  const PendingRequestSheet({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final PendingTransferRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
}
```

---

### TransferStatusBar

**Location**: `lib/src/core/widgets/transfer_status_bar.dart`

```dart
class TransferStatusBar extends ConsumerWidget {
  const TransferStatusBar({super.key});
  
  // Automatically watches transferStatusBarProvider
  // No external configuration needed
}
```

---

## Event Flow

### Accept/Decline Flow

```
1. Server receives /api/v1/info request
2. ServerIsolate sends HandshakeReceivedEvent to main isolate
3. ServerController creates PendingTransferRequest
4. ServerState updated with pendingRequest
5. ReceiveScreen shows PendingRequestSheet (bottom sheet)
6. User taps Accept/Decline
7. ServerController sends AcceptCommand/DeclineCommand to isolate
8. ServerIsolate responds to sender
9. ServerState clears pendingRequest
10. Bottom sheet dismisses
```

### Progress Update Flow

```
1. Transfer starts (send or receive)
2. Controller updates progress state
3. TransferStatusBarProvider recomputes state
4. TransferStatusBar widget rebuilds with new progress
5. On completion, state.isVisible becomes false
6. Status bar animates out
```

