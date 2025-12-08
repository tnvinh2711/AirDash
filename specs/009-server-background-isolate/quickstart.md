# Quickstart: Server Background Isolate Refactor

**Date**: 2025-12-07  
**Feature**: 009-server-background-isolate

## Prerequisites

- Flutter SDK via FVM (Flutter Version Management)
- Existing codebase with Spec 005 (File Transfer Server) implemented
- Run `flutter pub get` after any new dependencies

## Key Files to Create/Modify

### 1. Domain Models (Create)

```bash
# Create new domain files
touch lib/src/features/receive/domain/isolate_config.dart
touch lib/src/features/receive/domain/isolate_command.dart
touch lib/src/features/receive/domain/isolate_event.dart
```

After creating, run code generation:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. Session Status (Modify)

Update `lib/src/features/receive/domain/session_status.dart`:
- Rename `pending` → `awaitingAccept`
- Add `accepted` state
- Rename `receiving` → `inProgress`
- Add `cancelled` state

### 3. Server Isolate Manager (Create)

Create `lib/src/features/receive/data/server_isolate_manager.dart`:
- Implements `ServerIsolateManager` interface
- Uses `Isolate.spawn()` for isolate creation
- Establishes bidirectional SendPort/ReceivePort
- Provides `Stream<IsolateEvent>` for UI updates

### 4. Server Controller (Modify)

Update `lib/src/features/receive/application/server_controller.dart`:
- Replace direct `FileServerService` usage with `ServerIsolateManager`
- Map `IsolateEvent` to `ServerState` updates
- Add `respondToHandshake(requestId, accepted)` method

### 5. File Server Service (Modify)

Update `lib/src/features/receive/data/file_server_service.dart`:
- Remove prototype isolate code
- Keep Shelf router/handler logic for use inside isolate
- Extract entry point function for `Isolate.spawn()`

## Quick Verification

### Start Server in Isolate

```dart
final manager = ServerIsolateManager();

// Listen for events
manager.events.listen((event) {
  switch (event) {
    case ServerStartedEvent(:final port):
      print('Server started on port $port');
    case IncomingRequestEvent(:final requestId, :final fileName):
      print('Incoming: $fileName');
      // Auto-accept for testing
      manager.sendCommand(IsolateCommand.respondHandshake(
        requestId: requestId,
        accepted: true,
      ));
    case TransferProgressEvent(:final bytesReceived, :final totalBytes):
      print('Progress: ${(bytesReceived / totalBytes * 100).toInt()}%');
    case TransferCompletedEvent(:final savedPath):
      print('Saved to: $savedPath');
    case _:
      break;
  }
});

// Start with config
await manager.start(IsolateConfig(
  port: 53318,
  destinationPath: '/path/to/downloads',
  quickSaveEnabled: false,
));
```

### Test Socket Creation on Android

```bash
# From another machine on same network
nc -zv <android-device-ip> 53318
# Should show: Connection to <ip> 53318 port [tcp/*] succeeded!

curl http://<android-device-ip>:53318/api/v1/info
# Should return handshake response
```

## Build Commands

```bash
# Generate Freezed/Riverpod code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test test/features/receive/

# Run on Android device for isolate verification
flutter run -d <device-id>

# Check for lint errors
flutter analyze
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MAIN ISOLATE                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌────────────────────┐    ┌─────────────┐ │
│  │ ReceiveScreen│───▶│  ServerController  │───▶│ ServerState │ │
│  └──────────────┘    └────────────────────┘    └─────────────┘ │
│                              │                                  │
│                              ▼                                  │
│                    ┌────────────────────┐                       │
│                    │ServerIsolateManager│                       │
│                    └─────────┬──────────┘                       │
│                              │ SendPort / ReceivePort           │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────┐
│                              ▼         SERVER ISOLATE           │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌────────────────────┐                     │
│  │ Shelf Router │◀───│   HttpServer.bind  │ ◀── OS-level socket │
│  └──────┬───────┘    └────────────────────┘                     │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐    ┌────────────────────┐                     │
│  │/api/v1/info  │    │  /api/v1/upload    │                     │
│  │(handshake)   │    │  (file stream)     │                     │
│  └──────────────┘    └────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

