# Flux Transfer Flow Documentation

## Overview

Flux uses 3 main steps to send files between devices on the same local network:

1. **Discovery** - Find nearby devices using mDNS/DNS-SD
2. **Handshake** - Ask permission and get approval to send files
3. **Transfer** - Send the actual file over HTTP

---

## 1. Discovery Flow (mDNS/DNS-SD)

### Service Type
```
_flux._tcp
```

### Broadcast (Receiver)

When the receiver starts the server, it announces itself on the network using mDNS:

```
┌─────────────────┐                    ┌─────────────────┐
│    RECEIVER     │                    │     SENDER      │
│   (Server)      │                    │    (Client)     │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │  1. Start HTTP Server (port 53318)   │
         │                                      │
         │  2. Broadcast mDNS Service           │
         │  ─────────────────────────────────►  │
         │  Service: "_flux._tcp"               │
         │  TXT Records:                        │
         │    - alias: "MacBook Pro"            │
         │    - deviceType: "desktop"           │
         │    - os: "macOS"                     │
         │    - port: "53318"                   │
         │    - ips: "192.168.1.100"            │
         │                                      │
```

### Scan (Sender)

The sender scans the network to find devices that are broadcasting:

```
         │                                      │
         │  3. Start mDNS Discovery             │
         │  ◄─────────────────────────────────  │
         │  Listen for "_flux._tcp" services    │
         │                                      │
         │  4. Service Found Event              │
         │  ─────────────────────────────────►  │
         │  Device: {                           │
         │    alias: "MacBook Pro",             │
         │    ip: "192.168.1.100",              │
         │    port: 53318,                      │
         │    deviceType: desktop,              │
         │    os: "macOS"                       │
         │  }                                   │
         │                                      │
```

### Key Components

| Component | File | What it does |
|-----------|------|--------------|
| `DiscoveryRepository` | `discovery/data/discovery_repository.dart` | Handles mDNS broadcast and scan |
| `DiscoveryController` | `discovery/application/discovery_controller.dart` | Manages discovery state |
| `Device` | `discovery/domain/device.dart` | Model for discovered devices |
| `LocalDeviceInfo` | `discovery/domain/local_device_info.dart` | Info about the local device |

---

## 2. Handshake Flow

### API Endpoint
```
POST /api/v1/info
Content-Type: application/json
```

### Request Body (HandshakeRequest)
```json
{
  "fileName": "document.pdf",
  "fileSize": 1048576,
  "fileType": "pdf",
  "checksum": "abc123def456...",
  "isFolder": false,
  "fileCount": 1,
  "senderDeviceId": "uuid-device-id",
  "senderAlias": "iPhone 15"
}
```

### Response Body (HandshakeResponse)
```json
{
  "accepted": true,
  "sessionId": "uuid-session-id",
  "error": null
}
```

### Handshake Sequence

```
┌─────────────────┐                    ┌─────────────────┐
│    RECEIVER     │                    │     SENDER      │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │  1. User selects files               │
         │                                      │
         │  2. User taps target device          │
         │                                      │
         │  3. Prepare payload                  │
         │     - Compute MD5 checksum           │
         │     - Compress folder → ZIP          │
         │                                      │
         │  4. POST /api/v1/info                │
         │  ◄─────────────────────────────────  │
         │                                      │
         │  5. Validate request                 │
         │     - Check if busy                  │
         │     - Check storage space            │
         │                                      │
         │  6. Quick Save Mode?                 │
         │     ┌─ YES → Auto accept             │
         │     └─ NO  → Show popup to user      │
         │                                      │
         │  7. User accepts (timeout: 60s)      │
         │                                      │
         │  8. Response (accepted + sessionId)  │
         │  ─────────────────────────────────►  │
         │                                      │
```

### Rejection Cases

| Error Code | HTTP Status | What it means |
|------------|-------------|---------------|
| `busy` | 409 | Server is already receiving another file |
| `insufficient_storage` | 507 | Not enough disk space |
| `invalid_request` | 400 | Bad request format |
| `declined` | 403 | User said no |
| `timeout` | 408 | User did not respond within 60 seconds |

---

## 3. Transfer Flow

### API Endpoint
```
POST /api/v1/upload
Headers:
  X-Transfer-Session: <sessionId>
  X-File-Name: <url-encoded-filename>
  Content-Type: application/octet-stream
  Content-Length: <file-size>
Body: <binary file stream>
```

### Transfer Sequence

```
┌─────────────────┐                    ┌─────────────────┐
│    RECEIVER     │                    │     SENDER      │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │  1. POST /api/v1/upload              │
         │  ◄─────────────────────────────────  │
         │  Headers: X-Transfer-Session         │
         │  Body: <file bytes stream>           │
         │                                      │
         │  2. Validate session                 │
         │     - Check sessionId exists         │
         │     - Check not expired              │
         │                                      │
         │  3. Stream to disk                   │
         │     ┌────────────────────┐           │
         │     │ Progress: 25%     │           │
         │     │ Progress: 50%     │           │
         │     │ Progress: 75%     │           │
         │     │ Progress: 100%    │           │
         │     └────────────────────┘           │
         │                                      │
         │  4. Verify checksum                  │
         │     MD5(received) == MD5(expected)?  │
         │                                      │
         │  5. If folder: Extract ZIP           │
         │                                      │
         │  6. Response (success)               │
         │  ─────────────────────────────────►  │
         │  {"success": true}                   │
         │                                      │
         │  7. Record to history (both sides)   │
         │                                      │
```

### Upload Errors

| Error Code | HTTP Status | What it means |
|------------|-------------|---------------|
| `missing_session_id` | 400 | Missing X-Transfer-Session header |
| `session_not_found` | 404 | Session does not exist |
| `session_expired` | 410 | Session timed out (60 seconds) |
| `checksum_mismatch` | 422 | File was corrupted during transfer |

---

## 4. Complete Transfer Sequence

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│  SENDER  │          │  NETWORK │          │ RECEIVER │
│  (App)   │          │  (LAN)   │          │  (App)   │
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                     │
     │ ═══════════════════════════════════════════════════
     │                PHASE 1: DISCOVERY
     │ ═══════════════════════════════════════════════════
     │                     │                     │
     │                     │    Start Server     │
     │                     │◄────────────────────│
     │                     │                     │
     │                     │  Broadcast mDNS     │
     │                     │◄════════════════════│
     │                     │  "_flux._tcp"       │
     │                     │                     │
     │    Start Scan       │                     │
     │────────────────────►│                     │
     │                     │                     │
     │    Device Found     │                     │
     │◄════════════════════│                     │
     │    (IP, Port, Alias)│                     │
     │                     │                     │
     │ ═══════════════════════════════════════════════════
     │                PHASE 2: HANDSHAKE
     │ ═══════════════════════════════════════════════════
     │                     │                     │
     │    Select Files     │                     │
     │    Tap Device       │                     │
     │                     │                     │
     │    Compute Checksum │                     │
     │    (ZIP if folder)  │                     │
     │                     │                     │
     │   POST /api/v1/info │                     │
     │════════════════════►│════════════════════►│
     │   (metadata)        │                     │
     │                     │                     │
     │                     │    Show Popup       │
     │                     │    (if not QuickSave)
     │                     │                     │
     │                     │    User Accepts     │
     │                     │                     │
     │   Response: accepted│                     │
     │◄════════════════════│◄════════════════════│
     │   + sessionId       │                     │
     │                     │                     │
     │ ═══════════════════════════════════════════════════
     │                PHASE 3: TRANSFER
     │ ═══════════════════════════════════════════════════
     │                     │                     │
     │  POST /api/v1/upload│                     │
     │════════════════════►│════════════════════►│
     │  + sessionId header │                     │
     │  + file stream      │                     │
     │                     │                     │
     │                     │    Stream to disk   │
     │                     │    ████████████     │
     │                     │    Progress: 100%   │
     │                     │                     │
     │                     │    Verify checksum  │
     │                     │    Extract if ZIP   │
     │                     │                     │
     │   Response: success │                     │
     │◄════════════════════│◄════════════════════│
     │   + savedPath       │                     │
     │                     │                     │
     │   Record History    │    Record History   │
     │                     │                     │
     │   Show Complete     │    Show Complete    │
     │   Dialog            │    Dialog           │
     │                     │                     │
```



---

## 5. Key Components Reference

### Sender Side

| Component | File | What it does |
|-----------|------|--------------|
| `TransferController` | `send/application/transfer_controller.dart` | Runs the entire send flow |
| `TransferClientService` | `send/data/transfer_client_service.dart` | HTTP client using Dio |
| `CompressionService` | `send/data/compression_service.dart` | Zips folders and computes MD5 |
| `HandshakeRequest` | `send/data/dtos/handshake_request.dart` | Data model for POST /info |
| `FileSelectionController` | `send/application/file_selection_controller.dart` | Manages selected files |

### Receiver Side

| Component | File | What it does |
|-----------|------|--------------|
| `ServerController` | `receive/application/server_controller.dart` | Starts and stops the server |
| `FileServerService` | `receive/data/file_server_service.dart` | HTTP server using Shelf |
| `FileStorageService` | `receive/data/file_storage_service.dart` | Saves files to disk |
| `ServerIsolateManager` | `receive/application/server_isolate_manager.dart` | Runs server in background |
| `TransferMetadata` | `receive/domain/transfer_metadata.dart` | Parsed handshake data |

### Shared

| Component | File | What it does |
|-----------|------|--------------|
| `DiscoveryController` | `discovery/application/discovery_controller.dart` | mDNS scan and broadcast |
| `HistoryRepository` | `history/data/history_repository.dart` | Stores transfer history in SQLite |

---

## 6. State Machines

### Sender TransferState

```
┌─────────┐  select device  ┌───────────┐  checksum done  ┌─────────────┐
│  IDLE   │ ───────────────►│ PREPARING │ ───────────────►│ HANDSHAKING │
└─────────┘                 └───────────┘                 └──────┬──────┘
     ▲                                                           │
     │                                                    accepted│
     │         ┌──────────┐  complete   ┌───────────┐           │
     └─────────│ COMPLETE │◄────────────│  SENDING  │◄──────────┘
               └──────────┘             └─────┬─────┘
                    ▲                         │
                    │        rejected/error   │
               ┌────┴────┐◄───────────────────┘
               │ FAILED  │
               └─────────┘
```

### Receiver ServerState

```
┌─────────┐  startServer  ┌─────────┐  handshake  ┌─────────────┐
│ STOPPED │ ─────────────►│ RUNNING │ ───────────►│   PENDING   │
└─────────┘               └────┬────┘             │  (awaiting) │
     ▲                         │                  └──────┬──────┘
     │                         │                         │
     │  stopServer             │                  accept │
     │◄────────────────────────┤                         ▼
     │                         │                  ┌───────────┐
     │                         │    complete      │ RECEIVING │
     │                         │◄─────────────────┤           │
     │                         │                  └───────────┘
```

---

## 7. Error Handling

### Network Errors
- Connection timeout → Retry with backoff
- Connection refused → Device is offline or server stopped

### Transfer Errors
- Checksum mismatch → Delete file and show error to user
- Session expired → Ask sender to retry
- Insufficient storage → Reject handshake early

### Cancellation
- Sender cancels → Use `CancelToken` to abort upload
- Receiver rejects → Return decline response
