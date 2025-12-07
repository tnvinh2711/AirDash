# Feature Specification: Server Background Isolate Refactor

**Feature Branch**: `009-server-background-isolate`
**Created**: 2025-12-07
**Status**: Draft
**Input**: User description: "Refactor Server to Background Isolate - Refactor the existing HTTP Server logic to run in a separate Dart Isolate to solve OS-level socket creation issue on Android Main Isolate and prevent UI blocking during heavy file transfers"

## Clarifications

### Session 2025-12-07

- Q: How should the isolate handle incoming requests when Quick Save mode is enabled? → A: Auto-accept in isolate (no round-trip to main isolate)
- Q: What settings should be passed to the server isolate at startup? → A: Quick Save flag + destination path + receive mode
- Q: What are the valid states for a TransferSession? → A: AwaitingAccept → Accepted → InProgress → Completed/Failed/Cancelled

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Files Without UI Freezing (Priority: P1)

As a user receiving files on my Android device, I want the file transfer server to run smoothly in the background so that my app remains responsive and I can continue using other app features while files are being received.

**Why this priority**: This is the core problem being solved. The current implementation causes socket creation failures on Android Main Isolate and UI blocking during heavy transfers. Without this fix, the receive feature is fundamentally broken on Android.

**Independent Test**: Can be fully tested by starting the server on Android, sending a large file from another device, and verifying the UI remains responsive (animations smooth, navigation works) throughout the transfer.

**Acceptance Scenarios**:

1. **Given** the app is open on the Receive screen, **When** the server starts, **Then** the server binds successfully and the UI shows "Ready to receive" status within 2 seconds
2. **Given** the server is running, **When** a 100MB file transfer is in progress, **Then** all UI animations (progress bars, navigation transitions) remain smooth without frame drops
3. **Given** the server is running in an isolate, **When** I check Android's process list, **Then** the socket is visible at the OS level and accepts external connections

---

### User Story 2 - Accept or Reject Incoming File Requests (Priority: P1)

As a receiving user, when a sender initiates a file transfer, I want to see the sender's device info and file details so I can decide whether to accept or reject the transfer.

**Why this priority**: This is the handshake flow defined in Spec 05 and is essential for user control over what files they receive. It must work correctly within the isolate architecture.

**Independent Test**: Can be tested by initiating a handshake request from another device and verifying the accept/reject dialog appears with correct information.

**Acceptance Scenarios**:

1. **Given** the server is running, **When** a sender hits the handshake endpoint with device info and file metadata, **Then** a dialog appears showing sender name, device type, and list of files with sizes
2. **Given** an incoming request dialog is shown, **When** I tap "Accept", **Then** the sender receives a success response and can proceed with upload
3. **Given** an incoming request dialog is shown, **When** I tap "Reject", **Then** the sender receives a rejection response and the dialog closes
4. **Given** an incoming request dialog is shown, **When** I take no action for 60 seconds, **Then** the request times out and the sender receives a timeout response

---

### User Story 3 - Monitor Transfer Progress in Real-Time (Priority: P2)

As a receiving user, I want to see the file transfer progress updating smoothly in the UI so I know how much data has been received and can estimate completion time.

**Why this priority**: Progress feedback is important for user experience but is secondary to the core transfer functionality working correctly.

**Independent Test**: Can be tested by sending a large file and verifying the progress percentage updates regularly without flooding the UI or causing lag.

**Acceptance Scenarios**:

1. **Given** a file transfer is accepted and in progress, **When** bytes are being received, **Then** the progress indicator updates at least every 500ms showing current progress percentage
2. **Given** multiple files are being transferred, **When** viewing the transfer screen, **Then** I see both individual file progress and overall transfer progress
3. **Given** a transfer is in progress, **When** the transfer completes, **Then** the UI shows a completion notification within 1 second of the last byte being written

---

### User Story 4 - Handle Server Errors Gracefully (Priority: P2)

As a user, when something goes wrong with the server (port busy, network error, disk full), I want to see a clear error message so I can take corrective action.

**Why this priority**: Error handling is crucial for a good user experience but is secondary to the happy path working correctly.

**Independent Test**: Can be tested by simulating error conditions (binding to busy port, disconnecting network) and verifying appropriate error messages appear.

**Acceptance Scenarios**:

1. **Given** the user attempts to start the server, **When** the requested port is already in use, **Then** the UI shows an error message "Port [X] is busy"
2. **Given** a file transfer is in progress, **When** the sender disconnects unexpectedly, **Then** the UI shows a transfer error and the partial file is cleaned up
3. **Given** a file transfer is in progress, **When** the disk becomes full, **Then** the UI shows an error "Insufficient storage space" and notifies the sender

---

### User Story 5 - Server Lifecycle Management (Priority: P3)

As a user, I want the server to continue running when I navigate to other screens or minimize the app so that I can receive files without keeping the app in the foreground.

**Why this priority**: Background operation is a quality-of-life improvement that can be addressed after core functionality works.

**Independent Test**: Can be tested by starting the server, navigating away from the Receive screen, and verifying the server still accepts connections.

**Acceptance Scenarios**:

1. **Given** the server is running on the Receive screen, **When** I navigate to Settings or History, **Then** the server continues running and accepting connections
2. **Given** the server is running, **When** I press the home button to minimize the app, **Then** the server continues running for at least 5 minutes
3. **Given** the server is running and the app is in background, **When** I return to the app, **Then** the server status is correctly reflected in the UI

---

### Edge Cases

- What happens when the isolate crashes unexpectedly? The main isolate should detect this and update UI to show server stopped with an error message.
- How does the system handle multiple simultaneous transfer requests? Only one active session is allowed at a time; additional requests receive a "busy" response.
- What happens if the user force-closes the app during a transfer? Partial files should be deleted on next app launch.
- How does the system handle very large files (>1GB)? Progress updates should be throttled to prevent memory issues, and streaming writes should be used.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST run the HTTP server in a separate background isolate, not on the main UI isolate
- **FR-002**: System MUST provide a manager component that handles spawning, communication, and termination of the server isolate
- **FR-003**: System MUST use type-safe message passing between the main isolate and server isolate for all commands and events
- **FR-004**: Main isolate MUST be able to send start/stop commands to the server isolate
- **FR-005**: Main isolate MUST be able to send accept/reject responses for incoming transfer requests
- **FR-006**: Server isolate MUST send status updates (running/stopped, IP, port, errors) to the main isolate
- **FR-007**: Server isolate MUST send incoming transfer request details (sender info, file list) to the main isolate
- **FR-008**: Server isolate MUST send progress updates during file transfers (throttled to prevent flooding)
- **FR-009**: Server isolate MUST send completion and error notifications to the main isolate
- **FR-010**: Server isolate MUST implement the handshake endpoint as defined in Spec 05
- **FR-011**: Server isolate MUST implement the upload endpoint as defined in Spec 05
- **FR-012**: Server isolate MUST wait for user decision before responding to handshake requests (using a deferred response mechanism), EXCEPT when Quick Save mode is enabled—in which case the isolate MUST auto-accept immediately without round-tripping to the main isolate
- **FR-013**: Server isolate MUST stream incoming file bytes directly to disk without buffering entire files in memory
- **FR-014**: System MUST throttle progress updates to no more than 10 updates per second to prevent flooding the main isolate
- **FR-015**: System MUST handle port binding failures gracefully and report the error to the main isolate
- **FR-016**: All data transferred between isolates MUST be serializable (primitive types or JSON-serializable objects)
- **FR-017**: System MUST record completed transfers in the history database via the main isolate

### Key Entities

- **IsolateCommand**: Represents commands sent from main isolate to server isolate (StartServer, StopServer, RespondHandshake). StartServer command MUST include: Quick Save enabled flag, destination path, and receive mode
- **IsolateEvent**: Represents events sent from server isolate to main isolate (ServerStatus, IncomingRequest, TransferProgress, TransferCompleted, TransferError)
- **ServerIsolateManager**: Manages the lifecycle of the server isolate and provides a stream of events to the UI layer
- **TransferSession**: Represents an active transfer session with its ID, sender info, files, and current status. Valid states: AwaitingAccept → Accepted → InProgress → Completed/Failed/Cancelled

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Server starts successfully on Android devices in under 2 seconds and creates a visible OS-level socket
- **SC-002**: UI remains responsive (60fps animations) during file transfers of any size up to 10GB
- **SC-003**: File transfer throughput is at least 90% of the device's network capacity (no significant overhead from isolate communication)
- **SC-004**: Progress updates appear in the UI within 500ms of data being received
- **SC-005**: Accept/Reject user action is reflected to the sender within 1 second of user tap
- **SC-006**: Memory usage during transfers stays constant regardless of file size (streaming, not buffering)
- **SC-007**: Server handles 10 consecutive transfer sessions without memory leaks or performance degradation
- **SC-008**: All endpoints from Spec 05 (handshake, upload) function correctly within the isolate architecture

## Assumptions

- The server only needs to handle one active transfer session at a time (as per existing Spec 05 design)
- File storage location and permissions are already handled by the existing FileStorageService
- The Bonsoir mDNS discovery service can remain on the main isolate as it's lightweight
- Progress throttling at 10 updates/second provides sufficient granularity for UI feedback
- Isolates on Android continue running briefly when app is backgrounded (full foreground service is out of scope for this feature)