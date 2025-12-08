# Feature Specification: Send Tab UI

**Feature Branch**: `008-send-ui`
**Created**: 2025-12-06
**Status**: Draft
**Input**: User description: "Tab 2 - Send UI: Create the Send tab for Selection and Discovery. Section 1: Selection (Top) with File, Folder, Text, Media buttons, selected items list with X to remove, and Drag & Drop support. Section 2: Devices (Bottom) with Nearby Devices header, Refresh Icon Button, device grid/list showing Icon (OS), Alias, IP. Tap device to Send (disabled if Selection empty)."

## Clarifications

### Session 2025-12-06

- Q: Device layout format (grid vs list)? → A: Grid layout (2-3 columns on mobile, 3-4 on desktop)
- Q: Selection persistence behavior? → A: Persist across sessions (survive app restart until manually cleared)
- Q: Maximum selection size limit? → A: Warn at threshold (warn at 1GB total, allow continue)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select Files to Send (Priority: P1)

As a user, I want to select files, folders, or text that I want to send to another device, so that I can prepare my content before choosing a recipient.

**Why this priority**: This is the fundamental action required before any transfer can happen. Without content selection, the Send feature has no purpose.

**Independent Test**: Can be fully tested by selecting various content types (file, folder, text) and verifying they appear in the selection list. Delivers core value of content preparation.

**Acceptance Scenarios**:

1. **Given** the Send tab is displayed, **When** user taps the "File" button, **Then** a file picker opens allowing single or multiple file selection
2. **Given** the Send tab is displayed, **When** user taps the "Folder" button, **Then** a folder picker opens allowing folder selection
3. **Given** the Send tab is displayed, **When** user taps the "Text" button, **Then** a text input dialog/area opens for entering text content
4. **Given** the Send tab is displayed, **When** user taps the "Media" button, **Then** a media picker opens showing photos/videos from the device gallery
5. **Given** files/folders/text have been selected, **When** the selection is complete, **Then** the items appear in the Selection list with name, size (for files), and a remove (X) button

---

### User Story 2 - Manage Selection List (Priority: P1)

As a user, I want to view and manage my selected items before sending, so that I can verify what I'm about to send and remove items I no longer want to include.

**Why this priority**: Essential for user confidence and control over what gets transferred. Critical for preventing accidental sends.

**Independent Test**: Can be tested by adding multiple items, then removing individual items via the X button. Delivers value of content management.

**Acceptance Scenarios**:

1. **Given** items exist in the Selection list, **When** user taps the "X" button on an item, **Then** that item is removed from the list
2. **Given** multiple items are selected, **When** viewing the Selection list, **Then** each item displays its name, type icon, and size (where applicable)
3. **Given** the Selection list is empty, **When** user views the Send tab, **Then** a placeholder/empty state message is shown (e.g., "No items selected")

---

### User Story 3 - Drag and Drop Files (Priority: P2)

As a desktop user, I want to drag and drop files directly into the app, so that I can quickly add content without navigating through file pickers.

**Why this priority**: Enhances user experience significantly on desktop platforms but is not essential for core functionality on mobile.

**Independent Test**: Can be tested by dragging files/folders from the desktop file manager onto the app window and verifying they appear in the Selection list.

**Acceptance Scenarios**:

1. **Given** the Send tab is displayed on desktop, **When** user drags files from the file manager onto the app, **Then** the files are added to the Selection list
2. **Given** the Send tab is displayed, **When** user drags a folder onto the app, **Then** the folder is added to the Selection list as a single item
3. **Given** files are being dragged over the app, **When** the cursor enters the drop zone, **Then** visual feedback indicates the drop area is active

---

### User Story 4 - View Nearby Devices (Priority: P1)

As a user, I want to see a list of nearby devices that I can send files to, so that I can choose the correct recipient.

**Why this priority**: Core functionality - users must be able to see available recipients to complete a transfer.

**Independent Test**: Can be tested by having multiple devices on the same network with AirDash/FLUX running and verifying they appear in the device list.

**Acceptance Scenarios**:

1. **Given** the Send tab is displayed, **When** nearby devices are discovered, **Then** they appear in the Devices section with OS icon, alias, and IP address
2. **Given** no nearby devices are found, **When** viewing the Devices section, **Then** an empty state message is shown (e.g., "No devices found")
3. **Given** multiple devices are discovered, **When** viewing the Devices section, **Then** devices are displayed in a grid or list format

---

### User Story 5 - Refresh Device Discovery (Priority: P2)

As a user, I want to manually refresh the device list, so that I can find newly connected devices without waiting for automatic discovery.

**Why this priority**: Improves user control but automatic discovery handles most cases.

**Independent Test**: Can be tested by tapping the refresh button and verifying the discovery scan restarts and updates the device list.

**Acceptance Scenarios**:

1. **Given** the Devices section is displayed, **When** user taps the Refresh icon button, **Then** the device discovery scan restarts
2. **Given** a refresh is in progress, **When** viewing the Devices section, **Then** a loading indicator is shown
3. **Given** the refresh completes, **When** new devices are found, **Then** they appear in the Devices list

---

### User Story 6 - Initiate File Transfer (Priority: P1)

As a user, I want to tap on a device to start sending my selected items, so that I can complete the file transfer.

**Why this priority**: This is the culmination of the Send flow - actually initiating the transfer.

**Independent Test**: Can be tested by selecting content, tapping a device, and verifying the transfer begins (integrates with transfer feature from spec 006).

**Acceptance Scenarios**:

1. **Given** items are selected AND a device is available, **When** user taps on the device, **Then** the transfer to that device is initiated
2. **Given** NO items are selected, **When** user views a device in the list, **Then** the device appears disabled/greyed out and is not tappable
3. **Given** items are selected, **When** user taps an available device, **Then** visual feedback confirms the transfer has started

---

### Edge Cases

- What happens when a selected file is deleted from disk before sending? System should detect and show error, removing the item from selection.
- What happens when the selected folder contains thousands of files? System should handle gracefully with progress indication during folder processing.
- What happens when text content is empty? The "Text" option should require non-empty content before adding to selection.
- What happens when drag and drop includes unsupported file types? System should accept all file types (no restrictions).
- What happens when a device disappears during device list view? System should update the list to remove unavailable devices.
- What happens when user selects the same file twice? System should prevent duplicate entries or inform the user.

## Requirements *(mandatory)*

### Functional Requirements

**Selection Section:**

- **FR-001**: System MUST display a Selection section at the top of the Send tab with four action buttons: File, Folder, Text, Media
- **FR-002**: System MUST provide a file picker when the "File" button is tapped, supporting multiple file selection
- **FR-003**: System MUST provide a folder picker when the "Folder" button is tapped
- **FR-004**: System MUST provide a text input interface when the "Text" button is tapped for entering text content to send
- **FR-005**: System MUST provide a media picker (photos/videos) when the "Media" button is tapped
- **FR-006**: System MUST display selected items in a list showing item name, type, and size (for files/folders)
- **FR-007**: Each item in the Selection list MUST have a visible "X" button to remove it from selection
- **FR-008**: System MUST support drag and drop functionality on desktop platforms for adding files/folders
- **FR-009**: System MUST show visual feedback when files are dragged over the drop zone
- **FR-010**: System MUST display an empty state when no items are selected
- **FR-010a**: System MUST persist the selection list across app restarts until items are manually cleared or successfully sent
- **FR-010b**: System MUST display a warning when total selection size exceeds 1GB, but allow user to continue with the transfer

**Devices Section:**

- **FR-011**: System MUST display a Devices section below the Selection section with a "Nearby Devices" header
- **FR-012**: System MUST display a Refresh icon button in the Devices section header
- **FR-013**: Tapping the Refresh button MUST trigger a device discovery scan restart (via DiscoveryController.restartScan())
- **FR-014**: System MUST display discovered devices showing: OS icon, device alias, and IP address
- **FR-015**: System MUST display devices in a grid layout (2-3 columns on mobile, 3-4 columns on desktop)
- **FR-016**: System MUST show an empty state when no devices are discovered
- **FR-017**: System MUST show a loading indicator while device discovery is in progress

**Interaction:**

- **FR-018**: Tapping a device MUST initiate file transfer when items are selected
- **FR-019**: Device items MUST be disabled (visually greyed out, not tappable) when the Selection list is empty
- **FR-020**: System MUST prevent duplicate items in the Selection list

### Key Entities

- **SelectionItem**: Represents a selected item to send; contains type (file/folder/text/media), name, path (for files), content (for text), and size. Persisted to local storage across app sessions.
- **DiscoveredDevice**: Represents a nearby device; contains alias, IP address, port, device type, and OS information (already defined in discovery feature)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select and add files to the selection list within 3 seconds of tapping the File button
- **SC-002**: Users can remove an item from the selection list with a single tap on the X button
- **SC-003**: Drag and drop operations on desktop complete within 1 second for files under 100MB
- **SC-004**: Nearby devices appear in the device list within 5 seconds of discovery scan
- **SC-005**: Tapping Refresh button triggers device scan restart within 500ms with visible feedback
- **SC-006**: 95% of users can successfully complete the send flow (select item → choose device → initiate transfer) on first attempt
- **SC-007**: Empty states are displayed immediately when Selection list or Device list has no items
- **SC-008**: Device items correctly reflect disabled state within 100ms of Selection list becoming empty

## Assumptions

- The discovery mechanism (DiscoveryController) from feature 004 is available and functional
- The transfer mechanism (TransferController) from feature 006 is available and functional
- File pickers use native platform APIs for file/folder/media selection
- Text content is sent as a temporary text file or inline data
- All file types are supported for transfer (no file type restrictions)
- Device discovery uses mDNS/DNS-SD as implemented in feature 004
