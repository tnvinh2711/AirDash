# Quickstart: Polish and Bug Fixes

**Feature**: 010-polish-and-fixes | **Date**: 2025-12-07

## Prerequisites

- Flutter SDK via FVM (stable channel)
- Existing AirDash codebase with features 001-009 implemented
- Android device or emulator for permission testing

## 1. Add Dependencies

```bash
# Add permission_handler for Android storage permissions
flutter pub add permission_handler
```

Update `android/app/build.gradle` if needed for permission_handler compatibility.

## 2. Bug Fixes Implementation Order

### Fix 1: Server Isolate Stream Close Error

**File**: `lib/src/features/receive/data/server_isolate_manager.dart`

```dart
// Add disposed flag
bool _disposed = false;

// Guard event additions
void _handleIsolateMessage(dynamic message) {
  if (_disposed || _eventController.isClosed) return;
  // ... existing logic
}

// Update dispose
Future<void> dispose() async {
  _disposed = true;
  await _receivePortSubscription?.cancel();
  await _eventController.close();
  // ... rest of cleanup
}
```

### Fix 2: Handshake Timeout

**File**: `lib/src/features/receive/data/server_isolate_manager.dart`

```dart
// Increase timeout and add retry
const _handshakeTimeout = Duration(seconds: 30);
const _maxRetries = 3;

Future<SendPort> _waitForHandshake() async {
  for (var attempt = 1; attempt <= _maxRetries; attempt++) {
    try {
      return await _receivePort.first.timeout(_handshakeTimeout);
    } on TimeoutException {
      if (attempt == _maxRetries) rethrow;
      developer.log('Handshake attempt $attempt failed, retrying...');
    }
  }
  throw TimeoutException('Handshake failed after $_maxRetries attempts');
}
```

### Fix 3: Port Display in IdentityCard

**File**: `lib/src/features/receive/presentation/widgets/identity_card.dart`

```dart
class IdentityCard extends ConsumerWidget {
  const IdentityCard({
    required this.isReceiving,
    this.actualPort,  // NEW: Pass from ServerState
    super.key,
  });

  final bool isReceiving;
  final int? actualPort;  // NEW

  // In build(), use actualPort ?? identity.port
}
```

### Fix 4: Device Discovery Staleness

**File**: `lib/src/features/discovery/application/discovery_controller.dart`

```dart
// Increase staleness timeout
static const _stalenessTimeout = Duration(minutes: 2);  // Was shorter
```

## 3. New UI Components

### Accept/Decline Bottom Sheet

**File**: `lib/src/features/receive/presentation/widgets/pending_request_sheet.dart`

```dart
class PendingRequestSheet extends ConsumerWidget {
  const PendingRequestSheet({required this.request, super.key});
  
  final PendingTransferRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Incoming Transfer'),
          Text('From: ${request.senderAlias}'),
          Text('File: ${request.fileName}'),
          Text('Size: ${_formatBytes(request.fileSize)}'),
          Row(
            children: [
              ElevatedButton(onPressed: _accept, child: Text('Accept')),
              OutlinedButton(onPressed: _decline, child: Text('Decline')),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Transfer Status Bar

**File**: `lib/src/core/widgets/transfer_status_bar.dart`

```dart
class TransferStatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferStatusBarProvider);
    if (!state.isVisible) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Expanded(child: Text(state.fileName, overflow: TextOverflow.ellipsis)),
          Text('${(state.progress * 100).toInt()}%'),
          SizedBox(width: 100, child: LinearProgressIndicator(value: state.progress)),
        ],
      ),
    );
  }
}
```

## 4. Testing

### Manual Test Checklist

1. **Stream Close Error**: Start/stop server rapidly 10 times - no errors in console
2. **Handshake Timeout**: Start server on slow device - should succeed within 30s
3. **Port Display**: Verify IdentityCard shows 53318 (not 8080) when server running
4. **Device Discovery**: Discover a device, wait 2+ minutes - should remain visible
5. **Accept/Decline**: Disable Quick Save, send file - bottom sheet appears
6. **Progress Bar**: Send large file - status bar shows progress on both devices
7. **Toast Notifications**: Complete transfer - toast appears
8. **Send History**: Send file, check history - entry appears with "Sent" direction
9. **Storage Permission**: Fresh Android install, receive file - permission dialog appears

### Run Tests

```bash
# Run all tests
flutter test

# Run specific feature tests
flutter test test/features/receive/
flutter test test/features/discovery/
```

## 5. Verification

After implementation, verify:

- [ ] No "Cannot add new events after calling close" errors in logs
- [ ] No handshake timeout errors during normal operation
- [ ] IdentityCard shows correct port (53318)
- [ ] Devices persist in discovery list for 2+ minutes
- [ ] Bottom sheet appears for incoming transfers (Quick Save off)
- [ ] Progress bar visible during transfers
- [ ] Toast notifications on transfer completion
- [ ] Send history entries appear in history screen
- [ ] Storage permission requested on Android before first save

