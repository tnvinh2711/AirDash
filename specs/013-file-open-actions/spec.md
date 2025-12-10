# Feature Specification: File Open Actions

**Feature Branch**: `013-file-open-actions`
**Created**: 2025-12-08
**Status**: Draft
**Input**: User description: "Add options to click to open file in transfer history. And when the file sent, the receive device need to show a popup to ask user need to open file or go to files path"

## Clarifications

### Session 2025-12-08

- Q: Should the completion popup auto-dismiss after a timeout, or stay until user dismisses? → A: Popup stays until user explicitly dismisses; each completed transfer shows its own popup (can stack if multiple transfers complete)
- Q: What should happen to existing history entries created before this feature (no saved path)? → A: Keep existing entries but disable open/show actions for them (show "Path not available")

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open File from Transfer History (Priority: P1 🎯 MVP)

As a user who has received files, I want to be able to tap on a completed transfer in my history and quickly open the file so that I can view its contents without manually navigating through my file system.

**Why this priority**: This is the primary way users will access their received files. Without this, users must manually locate files in their downloads folder, creating friction in the file transfer workflow.

**Independent Test**: Can be fully tested by receiving a file, opening transfer history, tapping on the entry, and verifying the file opens in the appropriate app. Delivers immediate value by providing quick file access.

**Acceptance Scenarios**:

1. **Given** a completed received transfer in history, **When** user taps on the history entry, **Then** the system opens the file using the device's default application for that file type
2. **Given** a completed received transfer for a folder, **When** user taps on the history entry, **Then** the system opens the file browser at the folder location
3. **Given** a received file that was moved or deleted, **When** user taps on the history entry, **Then** the system shows an appropriate error message (e.g., "File not found")
4. **Given** a sent transfer in history (no local file), **When** user taps on the history entry, **Then** the system shows the transfer details but does not attempt to open a file

---

### User Story 2 - Post-Transfer Completion Popup (Priority: P1 🎯 MVP)

As a user who just received a file, I want to see a popup immediately after the transfer completes that lets me choose to open the file or go to its location so that I can quickly access what was just sent to me.

**Why this priority**: This provides immediate access to just-received files at the moment of highest user intent. Without this, users must navigate to history or their file system to access the file.

**Independent Test**: Can be fully tested by receiving a file from another device and verifying a popup appears with "Open File" and "Show in Folder" options. Delivers immediate value by reducing steps to access received content.

**Acceptance Scenarios**:

1. **Given** a file transfer just completed successfully, **When** the transfer finishes, **Then** a popup appears with options to "Open File" or "Show in Folder"
2. **Given** the completion popup is displayed, **When** user taps "Open File", **Then** the file opens in the device's default application and the popup dismisses
3. **Given** the completion popup is displayed, **When** user taps "Show in Folder", **Then** the file browser opens at the file's location and the popup dismisses
4. **Given** the completion popup is displayed, **When** user taps outside the popup or presses back, **Then** the popup dismisses without any file action
5. **Given** a folder transfer just completed, **When** the transfer finishes, **Then** the popup shows "Open Folder" instead of "Open File"
6. **Given** a transfer failed or was cancelled, **When** the transfer ends, **Then** no completion popup is shown
7. **Given** multiple transfers complete in quick succession, **When** each transfer finishes, **Then** each shows its own popup (popups can stack/accumulate)
8. **Given** a completion popup is displayed, **When** no user action is taken, **Then** the popup remains visible until explicitly dismissed

---

### User Story 3 - Show in Folder Option (Priority: P2)

As a user viewing transfer history, I want an option to navigate directly to the folder containing a received file so that I can manage the file or see related files in the same location.

**Why this priority**: Provides additional utility for file management but is secondary to directly opening files. Some users prefer to manage files through the file system rather than opening directly.

**Independent Test**: Can be tested by receiving a file, viewing history, using a "Show in Folder" action, and verifying the file browser opens at the correct location.

**Acceptance Scenarios**:

1. **Given** a completed received transfer in history, **When** user long-presses or uses a menu action, **Then** a "Show in Folder" option is available
2. **Given** user selects "Show in Folder", **When** the action executes, **Then** the device's file browser opens with the file's parent directory displayed
3. **Given** the file's folder no longer exists, **When** user selects "Show in Folder", **Then** an appropriate error message is shown

---

### Edge Cases

- What happens when the file was received but later moved to a different location?
  - Show "File not found" error with a helpful message
- What happens when the file type has no associated application?
  - Show the file in its folder location instead, or display a message that no app can open this file type
- What happens when storage permissions are denied (Android)?
  - Request permissions and show an explanation if denied
- What happens when Quick Save is disabled and the user hasn't selected a save location?
  - The saved path should still be tracked based on where the user chose to save
- What happens for very old history entries where the path format may have changed?
  - Validate path before attempting to open; show error if invalid
- What happens to existing history entries created before this feature?
  - Keep existing entries but disable open/show actions; display "Path not available" message when tapped

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store the saved file path for each completed received transfer
- **FR-002**: System MUST allow users to tap on completed received transfers in history to open the file
- **FR-003**: System MUST use the device's default application to open files based on file type
- **FR-004**: System MUST display a completion popup when a file transfer is successfully received
- **FR-005**: Completion popup MUST include "Open File" and "Show in Folder" action buttons
- **FR-006**: System MUST allow users to dismiss the completion popup without taking action
- **FR-007**: Completion popup MUST remain visible until user explicitly dismisses it (no auto-dismiss timeout)
- **FR-008**: System MUST display a separate popup for each completed transfer (popups can stack when multiple transfers complete)
- **FR-009**: System MUST open the file browser at the file's parent directory when "Show in Folder" is selected
- **FR-010**: System MUST display an appropriate error message when a file no longer exists at the saved path
- **FR-011**: System MUST distinguish between sent and received transfers (open actions only apply to received files)
- **FR-012**: System MUST support opening both individual files and extracted folders
- **FR-013**: System MUST preserve existing history entries during migration (no data deletion)
- **FR-014**: System MUST display "Path not available" when user attempts to open a history entry with no saved path

### Key Entities

- **TransferHistoryEntry**: Extended to include `savedPath` (nullable text field for file/folder location on disk; null for sent transfers, failed/cancelled transfers, or pre-existing entries migrated from before this feature)
- **CompletedTransferInfo**: Already includes `savedPath`, used to populate the completion popup

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can access received files within 2 taps from the main screen (history → tap entry → file opens)
- **SC-002**: 95% of completed transfers show the completion popup within 1 second of transfer finishing
- **SC-003**: "Open File" action successfully opens files in under 2 seconds for files under 100MB
- **SC-004**: "Show in Folder" action successfully opens the file browser at the correct location
- **SC-005**: Error messages for missing files are displayed within 1 second of user action
- **SC-006**: History entries for received files visually indicate they are tappable/actionable
