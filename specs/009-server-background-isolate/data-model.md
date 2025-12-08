# Data Model: Server Background Isolate Refactor

**Date**: 2025-12-07  
**Feature**: 009-server-background-isolate

## Entity Definitions

### IsolateConfig

Configuration snapshot passed to server isolate at startup.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| port | int | Yes | Port number for HTTP server binding |
| destinationPath | String | Yes | Directory path for saving received files |
| quickSaveEnabled | bool | Yes | If true, auto-accept transfers without user prompt |

**File**: `lib/src/features/receive/domain/isolate_config.dart`

---

### IsolateCommand (Sealed Union)

Commands sent from main isolate to server isolate.

| Variant | Fields | Description |
|---------|--------|-------------|
| StartServer | IsolateConfig config | Start the HTTP server with given configuration |
| StopServer | (none) | Gracefully stop the HTTP server |
| RespondHandshake | String requestId, bool accepted | User's accept/reject decision for a pending transfer |

**File**: `lib/src/features/receive/domain/isolate_command.dart`

---

### IsolateEvent (Sealed Union)

Events sent from server isolate to main isolate.

| Variant | Fields | Description |
|---------|--------|-------------|
| ServerStarted | int port | Server successfully bound and listening |
| ServerStopped | (none) | Server has been shut down |
| ServerError | String message | Error during server operation |
| IncomingRequest | TransferMetadata metadata, String requestId | Handshake received, awaiting user decision |
| TransferProgress | String sessionId, int bytesReceived, int totalBytes | Upload progress update (throttled) |
| TransferCompleted | String sessionId, String savedPath, bool checksumVerified | File successfully received and verified |
| TransferFailed | String sessionId, String reason | Transfer failed with error |

**File**: `lib/src/features/receive/domain/isolate_event.dart`

---

### SessionStatus (Enum) - MODIFIED

Updated to match clarified state machine.

| Value | Description |
|-------|-------------|
| awaitingAccept | Handshake received, waiting for user decision |
| accepted | User accepted, ready for file upload |
| inProgress | File upload in progress |
| completed | Transfer finished successfully |
| failed | Transfer failed due to error |
| cancelled | Transfer cancelled by user or sender |

**File**: `lib/src/features/receive/domain/session_status.dart`

**State Transitions**:
```
awaitingAccept → accepted (user accepts)
awaitingAccept → cancelled (user rejects or timeout)
accepted → inProgress (upload starts)
inProgress → completed (checksum verified)
inProgress → failed (error during transfer)
inProgress → cancelled (user cancels or sender disconnects)
```

---

### TransferSession - MODIFIED

Add state transitions and requestId for handshake correlation.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| sessionId | String | Yes | UUID assigned after accept |
| requestId | String | Yes | UUID for correlating handshake response |
| metadata | TransferMetadata | Yes | File/folder info from sender |
| createdAt | DateTime | Yes | When session was created |
| status | SessionStatus | Yes | Current state in lifecycle |
| failureReason | String? | No | Error message if status is failed |

**File**: `lib/src/features/receive/domain/transfer_session.dart`

---

### ServerIsolateManager

Manages server isolate lifecycle and message routing.

| Property | Type | Description |
|----------|------|-------------|
| events | Stream\<IsolateEvent\> | Broadcast stream of events from isolate |
| isRunning | bool | Whether isolate is active |

| Method | Signature | Description |
|--------|-----------|-------------|
| start | Future\<void\> start(IsolateConfig config) | Spawn isolate and start server |
| stop | Future\<void\> stop() | Send stop command and await shutdown |
| sendCommand | void sendCommand(IsolateCommand cmd) | Send command to isolate |
| dispose | void dispose() | Clean up resources |

**File**: `lib/src/features/receive/data/server_isolate_manager.dart`

## Relationships

```
ServerController (application layer)
    │
    ├── uses → ServerIsolateManager (data layer)
    │              │
    │              └── spawns → Server Isolate
    │                              │
    │                              ├── runs → Shelf HTTP server
    │                              └── uses → FileStorageService patterns
    │
    └── updates → ServerState (domain)
                     │
                     └── contains → TransferSession (domain)
```

## Validation Rules

1. **IsolateConfig.port**: Must be 1-65535, typically 53318
2. **IsolateConfig.destinationPath**: Must be a valid writable directory
3. **IsolateCommand.RespondHandshake.requestId**: Must match a pending request
4. **SessionStatus transitions**: Must follow defined state machine
5. **TransferProgress.bytesReceived**: Must be <= totalBytes

