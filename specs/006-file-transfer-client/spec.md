# Feature Specification: File Transfer Client (Send Logic)

**Feature Branch**: `006-file-transfer-client`
**Created**: 2025-12-06
**Status**: Draft
**Input**: User description: "File Transfer Client (Send Logic) - Implement the Logic to select content and send to an IP. Data Layer: Use dio for HTTP requests, file_picker for files/directories, archive package for zipping folders. Application Logic: FileSelectionController with state (List of SelectedItems), actions (pickFiles, pickFolder, pasteText, clearSelection). TransferController with sendPayload action (Handshake → Upload). Testing: Unit test for folder selection creating valid zip file."

## Clarifications

### Session 2025-12-06

- Q: When multiple items are selected, how should they be transferred? → A: Sequential - Transfer items one at a time, each with its own handshake/upload cycle
- Q: Should users be able to cancel a transfer in progress? → A: Yes, with cleanup - abort upload, clean up temp files, notify receiver
- Q: Should the sender record a history of sent transfers? → A: Yes - Record sent transfers in history (integrates with HistoryRepository from Spec 03)
- Q: When one item in a multi-item transfer fails, what should happen? → A: Continue - Skip failed item, continue with remaining items, report partial success at end
- Q: Should users be able to select multiple files in a single picker dialog? → A: Yes - Multi-select allowed in single picker dialog

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Send Single File (Priority: P1)

As a sending user, I want to select a file from my device and send it to another device on the same network, so that I can share files quickly without cloud services or cables.

**Why this priority**: This is the core functionality - sending a single file is the fundamental purpose of the client. Without this, the feature has no value.

**Independent Test**: Can be fully tested by selecting a file, choosing a discovered receiver device, initiating transfer, and verifying the file is received correctly on the other device.

**Acceptance Scenarios**:

1. **Given** a file is selected and a receiver device is available, **When** the user initiates send, **Then** the system performs handshake with metadata (filename, size, checksum) and uploads the file.
2. **Given** a transfer is in progress, **When** the file upload completes, **Then** the system receives confirmation of successful transfer and checksum verification.
3. **Given** a transfer is in progress, **When** the user views status, **Then** the system displays upload progress (percentage or bytes sent).

---

### User Story 2 - Send Folder as ZIP (Priority: P1)

As a sending user, I want to select a folder and send it to another device, so that I can transfer organized collections of files while preserving their structure.

**Why this priority**: Folder transfer is a core use case alongside single file transfer. The compression requirement makes this technically distinct but equally essential for the MVP.

**Independent Test**: Can be fully tested by selecting a folder, verifying it's compressed internally, sending to a receiver, and confirming the folder structure is preserved on extraction.

**Acceptance Scenarios**:

1. **Given** a folder is selected, **When** the user initiates send, **Then** the system compresses the folder into a temporary archive with preserved directory structure.
2. **Given** a folder is selected and compressed, **When** the transfer begins, **Then** the handshake metadata indicates this is a folder transfer (isFolder=true).
3. **Given** a folder transfer completes, **When** the receiver extracts the archive, **Then** the original directory structure is preserved.

---

### User Story 3 - Send Text Content (Priority: P2)

As a sending user, I want to paste text content and send it to another device, so that I can quickly share snippets, notes, or clipboard content without creating a file first.

**Why this priority**: Text sharing is a convenience feature that extends beyond files. It provides value but is not essential for core file transfer functionality.

**Independent Test**: Can be fully tested by pasting text into the app, sending to a receiver, and verifying the text arrives as a readable file.

**Acceptance Scenarios**:

1. **Given** text is pasted into the app, **When** the user views selection state, **Then** the text appears as a selectable item of type "Text".
2. **Given** text content is selected for transfer, **When** the transfer begins, **Then** the text is sent as a .txt file with a generated filename.
3. **Given** text transfer completes, **When** the receiver opens the file, **Then** the content matches the original pasted text exactly.

---

### User Story 4 - Manage Selection (Priority: P2)

As a sending user, I want to manage my selection of files/folders/text before sending, so that I can review what will be sent and remove unwanted items.

**Why this priority**: Selection management improves usability but is not strictly required for the core transfer flow. Users can still send content without clearing/modifying selections.

**Independent Test**: Can be fully tested by adding multiple items to selection, verifying the list displays correctly, removing items, and confirming the selection is updated.

**Acceptance Scenarios**:

1. **Given** items are selected, **When** the user views the selection list, **Then** all selected items are displayed with their type (File/Folder/Text) and path/preview.
2. **Given** items are in the selection, **When** the user clears selection, **Then** all items are removed from the selection list.
3. **Given** multiple items are selected, **When** the user removes a specific item, **Then** only that item is removed from the selection.

---

### Edge Cases

- What happens when the selected file is deleted or moved before transfer starts? (Transfer fails with appropriate error; user is notified to reselect)
- What happens when the receiver rejects the handshake (busy status)? (User is notified that receiver is busy; suggestion to retry later)
- What happens when the transfer fails mid-stream (network error)? (Partial transfer is abandoned; user is notified of failure; can retry)
- What happens when the receiver reports checksum mismatch? (Transfer marked as failed; user is notified of integrity error; can retry)
- What happens when compressing a very large folder? (Progress indicator for compression phase; timeout handling for extremely large folders)
- What happens when pasting text exceeds a reasonable size? (Assumption: Warn user if text exceeds 10MB; allow continuation with confirmation)
- What happens when no receiver device is selected? (Send button disabled; user must select a target device first)

## Requirements *(mandatory)*

### Functional Requirements

**Content Selection**
- **FR-001**: System MUST allow users to select one or more files from the device file system via multi-select file picker dialog
- **FR-001a**: System MUST allow users to invoke file picker multiple times to add more files to existing selection
- **FR-002**: System MUST allow users to select a folder from the device file system
- **FR-003**: System MUST compress selected folders into a temporary archive before transfer
- **FR-004**: System MUST preserve directory structure when compressing folders
- **FR-005**: System MUST allow users to paste text content for transfer
- **FR-006**: System MUST maintain a selection state containing zero or more items (files, folders, or text)
- **FR-007**: System MUST track item type (File/Folder/Text) and path/content for each selected item
- **FR-008**: System MUST allow users to clear all selections
- **FR-009**: System MUST allow users to remove individual items from selection

**Transfer Protocol (Client Side)**
- **FR-010**: System MUST compute checksum of file/archive before initiating transfer
- **FR-011**: System MUST perform handshake with receiver before uploading data (POST /api/v1/info)
- **FR-012**: System MUST send correct metadata in handshake: filename, fileSize, fileType, checksum, isFolder, fileCount, senderDeviceId, senderAlias
- **FR-013**: System MUST handle handshake rejection responses (busy, insufficient_storage, invalid_request)
- **FR-014**: System MUST stream file data to upload endpoint using session ID from handshake (POST /api/v1/upload)
- **FR-015**: System MUST include required headers: Content-Type, X-Transfer-Session, Content-Length
- **FR-016**: System MUST handle upload response codes (success, invalid_session, session_expired, checksum_mismatch, storage_error)
- **FR-016a**: When multiple items are selected, system MUST transfer items sequentially (one handshake/upload cycle per item)

**State Management**
- **FR-017**: System MUST track transfer state (Idle, Preparing, Sending, Completed, Failed, Cancelled)
- **FR-018**: System MUST track transfer progress (bytes sent, percentage if total size known; for multi-item transfers: current item index and total item count)
- **FR-019**: System MUST expose selection and transfer state to the UI layer
- **FR-019a**: System MUST allow users to cancel an in-progress transfer
- **FR-019b**: On cancellation, system MUST abort upload, clean up temporary files, and return to Idle state

**Text Content Handling**
- **FR-020**: System MUST convert text content to a .txt file for transfer
- **FR-021**: System MUST generate a filename for text content (e.g., "Pasted Text - [timestamp].txt")

**Error Handling**
- **FR-022**: System MUST clean up temporary compressed files after transfer (success or failure)
- **FR-023**: System MUST notify users of transfer failures with actionable error messages
- **FR-024**: System MUST allow retry of failed transfers without re-selecting content
- **FR-024a**: In multi-item transfers, system MUST continue with remaining items when one item fails
- **FR-024b**: System MUST report partial success summary at end of multi-item transfer (X of Y items succeeded)
- **FR-024c**: System MUST allow retry of only failed items from a partial transfer

**History Integration**
- **FR-025**: System MUST record completed transfers in the history repository (Spec 03 integration)
- **FR-026**: System MUST record failed/cancelled transfers in history with failure reason
- **FR-027**: History entries MUST include: filename, file size, recipient device info, timestamp, and transfer outcome

### Key Entities

- **SelectedItem**: Represents an item in the selection queue, containing: path (for files/folders), content (for text), type (File/Folder/Text), display name, and size estimate
- **TransferPayload**: Prepared transfer data including: source path or content, metadata for handshake, computed checksum, and isFolder flag
- **TransferState**: Current state of the transfer process (Idle, Preparing, Sending, Completed, PartialSuccess, Failed, Cancelled) with optional progress information, error details, and per-item outcome tracking for multi-item transfers
- **TargetDevice**: Information about the receiver device from discovery (IP address, port, device name, device ID)

## Assumptions

- The device discovery feature (Spec 04) provides available receiver devices to select from
- The file transfer server (Spec 05) is running on the receiver device and implements the expected API
- Authentication between devices is not required for MVP (LAN-only, trusted network assumption)
- Temporary compressed files are stored in the system temp directory
- Text content larger than 10MB prompts a warning but is allowed with user confirmation
- Maximum individual file size: No hard limit (relies on receiver storage check during handshake)
- The app has necessary file system read permissions (assumed handled by platform setup)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select and send a file of up to 1GB in size successfully on the same LAN
- **SC-002**: File selection dialog appears within 1 second of user action
- **SC-003**: Folder compression completes within 30 seconds for folders up to 500MB
- **SC-004**: Transfer progress updates are visible to the user within 500ms of state change
- **SC-005**: 100% of transfers include checksum for verification by receiver
- **SC-006**: Failed transfers provide user-friendly error messages within 2 seconds of failure
- **SC-007**: Temporary compressed files are cleaned up within 10 seconds of transfer completion
- **SC-008**: Users can complete the entire send flow (select → send → complete) in under 2 minutes for typical files (<100MB)
