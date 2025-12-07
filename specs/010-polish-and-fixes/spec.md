# Feature Specification: Polish and Bug Fixes

**Feature Branch**: `010-polish-and-fixes`
**Created**: 2025-12-07
**Status**: Draft
**Input**: Address critical stability issues, implement accept/decline flow, add transfer progress indicators, completion notifications, fix send history, storage permissions, device discovery persistence, and port display issues.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Server Stability and Reliability (Priority: P1)

As a receiving user, I want the file transfer server to start reliably every time, so that I can receive files without encountering errors or timeouts.

**Why this priority**: Critical foundation - users cannot receive any files if the server fails to start. The handshake timeout and stream state errors completely block core functionality.

**Independent Test**: Start the app, enable receive mode, and verify server starts successfully 10 consecutive times without timeout or stream errors.

**Acceptance Scenarios**:

1. **Given** the app is launched and receive mode is enabled, **When** the server starts, **Then** the server handshake completes successfully within a reasonable timeout period (no "Handshake TIMEOUT" error)
2. **Given** the server is running and handling transfers, **When** the server is stopped or restarted, **Then** no "Cannot add new events after calling close" errors occur
3. **Given** the server has been stopped, **When** the user re-enables receive mode, **Then** the server restarts cleanly without residual stream state issues

---

### User Story 2 - Accept/Decline Incoming Transfers (Priority: P1)

As a receiving user with Quick Save disabled, I want to see a prompt to accept or decline incoming file transfer requests, so that I can control which files I receive.

**Why this priority**: Critical for user control and security - users must be able to decide whether to accept files, especially when receiving from unknown senders.

**Independent Test**: Disable Quick Save, have another device send a file, verify the accept/decline dialog appears and both actions work correctly.

**Acceptance Scenarios**:

1. **Given** Quick Save is disabled and a file transfer request arrives, **When** the request is received, **Then** a dialog/UI is displayed showing sender information, file name, and file size with Accept and Decline buttons
2. **Given** an incoming transfer prompt is displayed, **When** the user taps Accept, **Then** the file transfer begins and progress is shown
3. **Given** an incoming transfer prompt is displayed, **When** the user taps Decline, **Then** the transfer is rejected and the sender is notified
4. **Given** an incoming transfer prompt is displayed, **When** the prompt times out (30 seconds), **Then** the transfer is automatically declined

---

### User Story 3 - Transfer Progress Visibility (Priority: P2)

As a user (sender or receiver), I want to see the progress of ongoing file transfers, so that I know how much time remains and whether the transfer is proceeding normally.

**Why this priority**: Essential user feedback - without progress indicators, users don't know if transfers are working or stuck.

**Independent Test**: Initiate a file transfer of a large file (>10MB), verify progress is visible on both sending and receiving devices.

**Acceptance Scenarios**:

1. **Given** a file transfer is in progress on the sending device, **When** viewing the send screen, **Then** a progress indicator shows transfer percentage and/or progress bar
2. **Given** a file transfer is in progress on the receiving device, **When** viewing the receive screen, **Then** a progress indicator shows transfer percentage and/or progress bar
3. **Given** multiple files are being transferred, **When** viewing the transfer UI, **Then** overall progress is clearly displayed

---

### User Story 4 - Transfer Completion Notifications (Priority: P2)

As a user, I want to be notified when a file transfer is complete, so that I know I can access the received file or that my sent file was delivered.

**Why this priority**: Important feedback loop - users need confirmation that transfers succeeded.

**Independent Test**: Complete a file transfer, verify both sender and receiver see completion notifications.

**Acceptance Scenarios**:

1. **Given** a file transfer completes successfully, **When** the transfer finishes on the sending device, **Then** a notification or UI message confirms "File sent successfully"
2. **Given** a file transfer completes successfully, **When** the transfer finishes on the receiving device, **Then** a notification or UI message confirms "File received successfully"
3. **Given** a transfer fails, **When** the failure occurs, **Then** both sender and receiver are notified of the failure with an appropriate error message

---

### User Story 5 - Send History Recording (Priority: P2)

As a sender, I want my sent files to be recorded in the transfer history, so that I can track what files I've sent and to whom.

**Why this priority**: Feature completeness - receive history works but send history appears broken, creating an inconsistent experience.

**Independent Test**: Send multiple files to different devices, verify all transfers appear in the send history with correct details.

**Acceptance Scenarios**:

1. **Given** a file is sent successfully, **When** the transfer completes, **Then** an entry is recorded in the send history with file name, recipient, timestamp, and status
2. **Given** a file send fails, **When** the failure occurs, **Then** an entry is recorded with failure status
3. **Given** the user navigates to the history screen, **When** viewing the history, **Then** both sent and received transfers are visible

---

### User Story 6 - Storage Permission Handling (Priority: P2)

As a receiving user, I want the app to request storage permission when needed to save files, so that file transfers don't fail due to missing permissions.

**Why this priority**: Critical on Android - without proper permissions, received files cannot be saved, causing silent failures.

**Independent Test**: Fresh install, receive a file, verify storage permission prompt appears before saving.

**Acceptance Scenarios**:

1. **Given** a file transfer is accepted and storage permission is not granted, **When** the save operation begins, **Then** the app prompts the user for storage permission
2. **Given** storage permission is denied, **When** the user declines permission, **Then** an appropriate error message is shown and the transfer fails gracefully
3. **Given** storage permission is granted, **When** the file save occurs, **Then** the file is saved to the appropriate download location

---

### User Story 7 - Device Discovery Persistence (Priority: P3)

As a sender, I want discovered devices to remain visible in the device list reliably, so that I don't have to wait for re-discovery when a device temporarily drops and reappears.

**Why this priority**: User experience improvement - devices disappearing unexpectedly is confusing and frustrating.

**Independent Test**: Discover a device, wait 2-3 minutes, verify the device remains visible if it's still on the network.

**Acceptance Scenarios**:

1. **Given** a device is discovered on the network, **When** the device remains available, **Then** it stays in the device list without disappearing
2. **Given** a device temporarily becomes unreachable, **When** it becomes reachable again within a reasonable time (60 seconds), **Then** it reappears or remains in the list without requiring manual refresh
3. **Given** a device is truly offline, **When** the device has been unreachable for more than 2 minutes, **Then** it is removed from the list with appropriate indication

---

### User Story 8 - Correct Port Display (Priority: P3)

As a user, I want to see the actual server port in the Identity Card on the Receive screen, so that I can troubleshoot connection issues if needed.

**Why this priority**: Bug fix - showing hardcoded "8080" when the actual port may differ is misleading.

**Independent Test**: Start receive mode, verify the Identity Card shows the actual port the server is running on.

**Acceptance Scenarios**:

1. **Given** the server is running on a dynamically assigned port, **When** viewing the Identity Card on the Receive screen, **Then** the actual port number is displayed
2. **Given** the server port changes (e.g., due to restart), **When** viewing the Identity Card, **Then** the updated port is reflected

---

### Edge Cases

- What happens when multiple transfer requests arrive simultaneously when Quick Save is off?
  - Show requests in a queue, allow user to accept/decline each individually
- What happens if permission is revoked mid-transfer?
  - Fail the transfer gracefully and notify the user
- What happens if a device is discovered while another discovery scan is in progress?
  - Merge results, avoid duplicate entries
- What happens if the network changes during a transfer?
  - Fail with appropriate error message, allow retry
- What happens if storage is full?
  - Fail transfer with "Insufficient storage" error message

## Requirements *(mandatory)*

### Functional Requirements

**Server Stability**
- **FR-001**: System MUST complete server isolate handshake within 10 seconds under normal conditions
- **FR-002**: System MUST properly close all streams before shutting down the server isolate
- **FR-003**: System MUST handle server restart gracefully without residual state from previous instances

**Accept/Decline Flow**
- **FR-004**: System MUST display an accept/decline bottom sheet overlay when Quick Save is disabled and a transfer request arrives
- **FR-005**: The bottom sheet MUST show sender device name, file name(s), and total size with Accept and Decline action buttons
- **FR-006**: System MUST timeout pending requests after 30 seconds if no user action is taken (auto-dismiss bottom sheet)
- **FR-007**: System MUST notify the sender when a transfer is declined

**Transfer Progress**
- **FR-008**: System MUST display transfer progress (0-100%) in a dedicated status bar on the sending device during active transfers
- **FR-009**: System MUST display transfer progress (0-100%) in a dedicated status bar on the receiving device during active transfers
- **FR-010**: Progress updates MUST occur at least every second or every 5% change, whichever is more frequent
- **FR-010a**: The dedicated transfer status bar MUST be fixed at the top or bottom of the screen and visible regardless of scroll position

**Completion Notifications**
- **FR-011**: System MUST display an in-app toast/snackbar on the sender when transfer completes (visible only when app is in foreground)
- **FR-012**: System MUST display an in-app toast/snackbar on the receiver when transfer completes (visible only when app is in foreground)
- **FR-013**: System MUST display in-app failure toasts with error details when transfers fail

**Send History**
- **FR-014**: System MUST record all sent transfers in the history database
- **FR-015**: Send history entries MUST include: file name, recipient device name, timestamp, status (success/failed), and file size

**Storage Permissions**
- **FR-016**: System MUST check for storage permission before attempting to save received files
- **FR-017**: System MUST request storage permission from the user if not already granted
- **FR-018**: System MUST fail gracefully with user notification if permission is denied

**Device Discovery Persistence**
- **FR-019**: System MUST maintain discovered devices in the list for at least 2 minutes after last discovery confirmation
- **FR-020**: System MUST implement periodic liveness checks (every 30-60 seconds) to verify device availability
- **FR-021**: System MUST remove devices only after confirming they are truly offline

**Port Display**
- **FR-022**: The Identity Card on the Receive screen MUST display the actual server port, not a hardcoded value

### Key Entities

- **TransferRequest**: Represents an incoming file transfer request - includes sender device info, file metadata, timestamp, and acceptance status
- **TransferProgress**: Real-time transfer state - includes bytes transferred, total bytes, percentage, and estimated time remaining
- **TransferHistory**: Persistent record of completed transfers - includes direction (sent/received), file details, device info, timestamp, and status

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Server starts successfully in 100% of attempts (no handshake timeouts or stream errors after fix)
- **SC-002**: Accept/Decline prompt appears within 1 second of receiving a transfer request when Quick Save is off
- **SC-003**: Transfer progress is visible and updates in real-time on both devices for 100% of transfers
- **SC-004**: Completion notifications appear within 2 seconds of transfer completion on both devices
- **SC-005**: 100% of sent transfers are recorded in history (verified by database inspection)
- **SC-006**: Storage permission is requested before any file save operation on platforms requiring it
- **SC-007**: Discovered devices remain visible for at least 2 minutes while still on the network
- **SC-008**: The actual server port is displayed on the Receive screen Identity Card (verified by comparing with actual bound port)

## Assumptions

- Storage permission handling primarily targets Android; iOS and desktop platforms use standard file access
- The 30-second timeout for accept/decline prompts is reasonable for user interaction
- Device liveness checks at 30-60 second intervals provide adequate balance between responsiveness and network overhead
- The current architecture supports adding progress callbacks to the file transfer pipeline

## Clarifications

### Session 2025-12-07

- Q: What type of notification for transfer completion? → A: In-app toast/snackbar only (visible when app is in foreground)
- Q: What UI presentation style for accept/decline prompt? → A: Bottom sheet overlay (slides up from bottom, dismissible, less intrusive)
- Q: Where should transfer progress be displayed? → A: Dedicated transfer status bar (fixed bar at top or bottom of screen)
