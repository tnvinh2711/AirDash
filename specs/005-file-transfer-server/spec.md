# Feature Specification: File Transfer Server (Receive Logic)

**Feature Branch**: `005-file-transfer-server`
**Created**: 2025-12-06
**Status**: Draft
**Input**: User description: "File Transfer Server (Receive Logic) - Implement HTTP Server logic to accept incoming files and control server state. Server uses shelf and shelf_router with FileServerService Provider. Endpoints: POST /api/v1/info for handshake metadata exchange, POST /api/v1/upload for streaming file data. For folders, receive as ZIP stream or handle multi-file upload. ServerController manages state (isServerRunning, transferStatus) with toggleServer action that integrates with Discovery Broadcast (Spec 04). Update HistoryRepository on completion."

## Clarifications

### Session 2025-12-06

- Q: How should the server correlate an upload request with its handshake? → A: Server returns a session/transfer ID in handshake response; upload must include it
- Q: What should happen when a second sender requests a handshake while a transfer is in progress? → A: Immediately reject with "busy" status; sender should retry later
- Q: Should the server verify file integrity using checksums? → A: Required - Server MUST compute checksum after receive and verify against sender-provided value
- Q: What should happen if discovery broadcast fails when starting the server? → A: Start HTTP server anyway; log warning that device won't be discoverable

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Single File (Priority: P1)

As a receiving user, I want my device to accept and save an incoming file from another device on the same network, so that I can receive files without manual intervention once my server is running.

**Why this priority**: This is the core functionality - receiving a file is the fundamental purpose of the server. Without this, the feature has no value.

**Independent Test**: Can be fully tested by starting the server, sending a single file via HTTP request, and verifying the file is saved correctly to the device's designated receive folder.

**Acceptance Scenarios**:

1. **Given** the server is running and discoverable, **When** a sender initiates a file transfer with valid metadata, **Then** the server accepts the handshake and responds with readiness to receive.
2. **Given** a successful handshake has occurred, **When** the sender streams file data, **Then** the server saves the file to the designated receive location with the correct filename.
3. **Given** file transfer is in progress, **When** the transfer completes successfully, **Then** the server records the transfer in history and updates status to "Completed".

---

### User Story 2 - Toggle Server On/Off (Priority: P1)

As a user, I want to start and stop the file receive server with a single action, so that I can control when my device is discoverable and accepting files.

**Why this priority**: Users must be able to control server state for privacy and battery/resource management. This is co-equal with receiving files as it enables/disables the core functionality.

**Independent Test**: Can be tested by toggling the server on, verifying it's listening and broadcasting via discovery, then toggling off and verifying it stops listening and stops broadcasting.

**Acceptance Scenarios**:

1. **Given** the server is not running, **When** the user turns the server on, **Then** the HTTP server starts listening AND device discovery broadcast begins (integrating with Spec 04).
2. **Given** the server is running, **When** the user turns the server off, **Then** the HTTP server stops listening AND device discovery broadcast stops.
3. **Given** the server is running, **When** the app is closed or backgrounded, **Then** the server continues running (or follows platform-appropriate lifecycle behavior).

---

### User Story 3 - Receive Folder/Multiple Files (Priority: P2)

As a receiving user, I want to receive folders or multiple files in a single transfer session, so that I can receive organized collections of files together.

**Why this priority**: While single file transfer is the MVP, folder/batch transfer is a common use case that provides significant convenience. Deferred from P1 to reduce initial complexity.

**Independent Test**: Can be tested by sending a folder (as ZIP stream) or multiple files, verifying all contents are saved with correct structure in the receive location.

**Acceptance Scenarios**:

1. **Given** the server is running, **When** a sender transfers a folder as a compressed stream, **Then** the server receives and extracts the contents to a folder with the original structure preserved.
2. **Given** the server is running, **When** a sender transfers multiple files in sequence, **Then** the server receives and saves each file correctly.

---

### User Story 4 - View Transfer Status (Priority: P2)

As a user, I want to see the current status of any ongoing transfer, so that I know whether my device is idle, receiving, or has completed a transfer.

**Why this priority**: User feedback on transfer state improves UX but is not strictly required for the core transfer functionality.

**Independent Test**: Can be tested by observing status changes as a transfer progresses from Idle → Receiving → Completed.

**Acceptance Scenarios**:

1. **Given** no transfer is in progress, **When** the user views status, **Then** status shows "Idle".
2. **Given** a transfer is in progress, **When** the user views status, **Then** status shows "Receiving" with progress indication (bytes received or percentage if total size known).
3. **Given** a transfer has just completed, **When** the user views status, **Then** status shows "Completed" until dismissed or timeout.

---

### Edge Cases

- What happens when the server receives a file with a filename that already exists? (Assumption: Append a numeric suffix, e.g., `file (1).txt`)
- What happens when available storage space is insufficient for the incoming file? (Server should reject the transfer with an appropriate error after handshake or during upload)
- What happens when a transfer is interrupted mid-stream (network failure, sender cancels)? (Partial file is deleted, status returns to Idle, history records "Failed")
- What happens when the server receives malformed or invalid request data? (Server responds with appropriate error status, logs the issue, and continues listening)
- What happens when multiple senders try to transfer simultaneously? → Server immediately rejects with "busy" status; sender should retry later (no queueing)
- What happens when the handshake metadata indicates a file size larger than a configurable maximum? (Server rejects with error)
- What happens if discovery broadcast fails to start? → HTTP server starts anyway; warning logged; device can still receive if sender knows IP/port directly

## Requirements *(mandatory)*

### Functional Requirements

**Server Lifecycle**
- **FR-001**: System MUST provide an HTTP server that listens on a configurable port (default: dynamically assigned available port)
- **FR-002**: System MUST expose a provider/service for server lifecycle management
- **FR-003**: System MUST attempt to start discovery broadcast (Spec 04 integration) when server starts
- **FR-003a**: If discovery broadcast fails, system MUST still start HTTP server and log a warning indicating device won't be discoverable
- **FR-004**: System MUST stop discovery broadcast when server stops (if it was successfully started)

**Handshake Endpoint (POST /api/v1/info)**
- **FR-005**: System MUST accept a handshake request containing transfer metadata (filename, file size, file type, sender device info, and file checksum)
- **FR-005a**: System MUST reject handshake requests with "busy" status if a transfer is already in progress
- **FR-005b**: System MUST require a checksum value in handshake metadata for integrity verification
- **FR-006**: System MUST validate available storage before accepting a transfer
- **FR-007**: System MUST respond with acceptance/rejection, server capabilities, and a unique transfer session ID
- **FR-007a**: Transfer session ID MUST be generated per handshake and used to correlate subsequent upload requests

**Upload Endpoint (POST /api/v1/upload)**
- **FR-008**: System MUST accept streamed file data only when accompanied by a valid transfer session ID from a prior handshake
- **FR-008a**: System MUST reject upload requests with missing, invalid, or expired session IDs
- **FR-009**: System MUST save received data to the device's designated receive folder
- **FR-009a**: System MUST compute checksum of received file after upload completes
- **FR-009b**: System MUST verify computed checksum matches sender-provided checksum from handshake
- **FR-009c**: System MUST reject transfer and delete file if checksum verification fails (record as "Failed - integrity error" in history)
- **FR-010**: System MUST handle filename collisions by appending a numeric suffix
- **FR-011**: System MUST support receiving compressed folder transfers (ZIP stream)
- **FR-012**: System MUST extract folder contents while preserving directory structure

**State Management**
- **FR-013**: System MUST track server running state (on/off)
- **FR-014**: System MUST track transfer status (Idle, Receiving, Completed, Failed)
- **FR-015**: System MUST expose state to the UI layer via a controller/provider

**History Integration**
- **FR-016**: System MUST record completed transfers in the history repository (Spec 03 integration)
- **FR-017**: System MUST record failed/interrupted transfers in history with failure reason

**Error Handling**
- **FR-018**: System MUST respond with appropriate error codes for invalid requests
- **FR-019**: System MUST clean up partial files if transfer fails mid-stream
- **FR-020**: System MUST return to Idle status after transfer completion or failure

### Key Entities

- **TransferMetadata**: Information about an incoming transfer including filename, size, type, checksum (sender-provided for verification), sender device identifier, and server-generated transfer session ID (used to link handshake to upload)
- **TransferStatus**: Current state of the server/transfer (Idle, Receiving, Completed, Failed) with optional progress information
- **ServerState**: Combined state object containing isServerRunning flag, current port, and transfer status
- **ReceivedFile**: Record of a successfully received file including path, timestamp, sender info, and size for history tracking

## Assumptions

- The receive folder location will be a platform-appropriate default (e.g., Downloads folder) or configurable via settings (settings feature assumed future scope)
- Authentication/authorization between devices is not required for MVP (LAN-only, trusted network assumption)
- Maximum concurrent transfers: 1 (single transfer at a time for simplicity)
- Default maximum file size: No hard limit, but storage check at handshake
- Transfer session timeout: 5 minutes of inactivity before considering transfer failed
- The app has necessary file system permissions (assumed handled by platform setup)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can receive a file of up to 1GB in size successfully on the same LAN
- **SC-002**: Server starts and becomes discoverable within 2 seconds of toggle action
- **SC-003**: Server stops and becomes undiscoverable within 1 second of toggle action
- **SC-004**: 100% of file transfers are verified via checksum; transfers with mismatched checksums are rejected and recorded as failed
- **SC-005**: Transfer status updates are visible to the user within 500ms of state change
- **SC-006**: Interrupted transfers are cleaned up (partial files removed) within 5 seconds
- **SC-007**: Completed transfers appear in history immediately after completion
