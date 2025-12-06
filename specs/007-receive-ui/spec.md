# Feature Specification: Receive Tab UI

**Feature Branch**: `007-receive-ui`
**Created**: 2025-12-06
**Status**: Draft
**Input**: User description: "Tab 1 - Receive UI. Goal Create the Receive tab focusing on Identity and Server Control. Requirements: Layout with History Button, Identity Card, Server Control Toggle, Quick Save Switch, and HistoryView."

## Clarifications

### Session 2025-12-06

- Q: How should HistoryView be presented when opened? → A: Full Screen (dedicated route with back navigation)
- Q: What should be the default Receive Mode state on app launch? → A: Remember last state (persist user's previous choice across restarts)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Device Identity (Priority: P1)

As a user, I want to see my device's identity information (avatar, alias, IP address, and port) so that I can share my connection details with other users who want to send files to me.

**Why this priority**: This is the core information users need to identify their device on the network. Without this, users cannot receive files because senders won't know how to reach them.

**Independent Test**: Can be fully tested by opening the Receive tab and verifying the Identity Card displays the device avatar, alias, IP address, and port. Delivers immediate value by showing users their network identity.

**Acceptance Scenarios**:

1. **Given** the user opens the Receive tab, **When** the tab loads, **Then** the Identity Card displays in the center of the screen showing the device avatar, alias, IP address, and port.
2. **Given** the Identity Card is displayed, **When** the user taps/clicks the IP address, **Then** the IP address is copied to the clipboard and a confirmation message appears.
3. **Given** the device's network configuration changes, **When** the IP address updates, **Then** the Identity Card reflects the new IP address.

---

### User Story 2 - Toggle Receive Mode (Priority: P1)

As a user, I want to toggle my device's receive mode on/off so that I can control when my device is visible and accepting file transfers from other devices.

**Why this priority**: This is essential for the core receive functionality. Users must be able to enable receiving to accept files and disable it for privacy/battery conservation.

**Independent Test**: Can be fully tested by toggling the Receive Mode switch and observing the visual feedback (pulse animation, status text) and verifying discovery is enabled/disabled accordingly.

**Acceptance Scenarios**:

1. **Given** the Receive Mode is off, **When** the user toggles it on, **Then** a pulse animation starts, the status changes to "Ready", and the device becomes discoverable on the network.
2. **Given** the Receive Mode is on, **When** the user toggles it off, **Then** the pulse animation stops, the status changes to "Offline", and the device is no longer discoverable.
3. **Given** the Receive Mode is on, **When** the avatar is displayed, **Then** it shows an animated state indicating active receiving.
4. **Given** the Receive Mode is off, **When** the avatar is displayed, **Then** it shows a static state indicating inactive status.

---

### User Story 3 - Toggle Quick Save Mode (Priority: P2)

As a user, I want to enable/disable auto-accept for incoming transfers so that I can either automatically receive files from trusted senders or manually approve each transfer.

**Why this priority**: This enhances user experience by providing flexibility in how transfers are handled, but the core receive functionality works without it.

**Independent Test**: Can be fully tested by toggling the Quick Save switch and verifying the preference is saved and applied to incoming transfers.

**Acceptance Scenarios**:

1. **Given** Quick Save is off, **When** the user enables it, **Then** incoming transfers are automatically accepted without prompting the user.
2. **Given** Quick Save is on, **When** the user disables it, **Then** incoming transfers require manual approval before being accepted.
3. **Given** the user changes the Quick Save setting, **When** the app is closed and reopened, **Then** the setting is persisted and restored.

---

### User Story 4 - View Transfer History (Priority: P2)

As a user, I want to view my transfer history so that I can see past sent and received files and access them if needed.

**Why this priority**: While not required for receiving files, transfer history improves usability by letting users track their transfers and access previously received files.

**Independent Test**: Can be fully tested by opening the History view and verifying that transfer records are displayed with correct icons distinguishing sent vs received items.

**Acceptance Scenarios**:

1. **Given** the user is on the Receive tab, **When** they tap the History button (top-right), **Then** the HistoryView opens showing a list of transfer records.
2. **Given** the HistoryView is open, **When** viewing a sent transfer, **Then** an upward arrow icon is displayed next to the item.
3. **Given** the HistoryView is open, **When** viewing a received transfer, **Then** a downward arrow icon is displayed next to the item.
4. **Given** the HistoryView is open with transfer records, **When** viewing the list, **Then** each item shows relevant details (file name, date/time, status).
5. **Given** there are no transfer records, **When** the HistoryView opens, **Then** an empty state message is displayed.

---

### Edge Cases

- What happens when the device has no network connection? The IP address should show "Not Connected" or similar placeholder.
- What happens when the device has multiple IP addresses (e.g., WiFi and cellular)? Display the primary local network IP used for transfers.
- How does the system handle toggling Receive Mode while a transfer is in progress? The current transfer should complete, but no new transfers are accepted.
- What happens if Quick Save is enabled but storage is full? The transfer should fail gracefully with an appropriate error message.

## Requirements *(mandatory)*

### Functional Requirements

**Layout & Navigation**
- **FR-001**: System MUST display a History button in the top-right corner of the Receive tab.
- **FR-002**: System MUST display the Identity Card in the center of the Receive tab.
- **FR-003**: System MUST navigate to a full-screen HistoryView when the History button is tapped (dedicated route with back navigation).

**Identity Card**
- **FR-004**: Identity Card MUST display the device's avatar with animation capability.
- **FR-005**: Identity Card MUST display the device's alias (friendly name).
- **FR-006**: Identity Card MUST display the device's current IP address.
- **FR-007**: Identity Card MUST display the device's port number used for transfers.
- **FR-008**: Users MUST be able to copy the IP address to clipboard by tapping it.
- **FR-009**: System MUST provide visual feedback when IP address is copied.

**Server Control**
- **FR-010**: System MUST provide a prominent toggle switch labeled "Receive Mode".
- **FR-011**: System MUST display a pulse animation on the avatar when Receive Mode is on.
- **FR-012**: System MUST display "Ready" status text when Receive Mode is on.
- **FR-013**: System MUST stop the pulse animation when Receive Mode is off.
- **FR-014**: System MUST display "Offline" status text when Receive Mode is off.
- **FR-015**: System MUST enable network discovery when Receive Mode is turned on.
- **FR-016**: System MUST disable network discovery when Receive Mode is turned off.
- **FR-016a**: System MUST persist Receive Mode state across app sessions and restore it on launch (default OFF for fresh install).

**Quick Save**
- **FR-017**: System MUST provide a Quick Save toggle switch for auto-accept functionality.
- **FR-018**: System MUST persist the Quick Save preference across app sessions.
- **FR-019**: When Quick Save is enabled, system MUST automatically accept incoming transfers.
- **FR-020**: When Quick Save is disabled, system MUST prompt user for approval on incoming transfers.

**History View**
- **FR-021**: HistoryView MUST display a list of TransferHistory records from the database.
- **FR-022**: HistoryView MUST display an upward arrow icon for sent transfers.
- **FR-023**: HistoryView MUST display a downward arrow icon for received transfers.
- **FR-024**: HistoryView MUST display an empty state when no transfer records exist.

### Key Entities

- **Identity Card**: Visual component representing the device's network identity; contains avatar, alias, IP address, and port.
- **Receive Mode State**: Boolean state controlling whether the device is discoverable and accepting transfers; affects animation, status text, and discovery service.
- **Quick Save Setting**: User preference determining whether incoming transfers are auto-accepted or require manual approval.
- **TransferHistory**: Existing database entity representing past transfers; contains direction (sent/received), file info, timestamps, and status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view their device identity (avatar, alias, IP, port) within 1 second of opening the Receive tab.
- **SC-002**: Users can copy IP address with a single tap and receive visual confirmation within 500ms.
- **SC-003**: Receive Mode toggle responds within 500ms with appropriate visual feedback (animation start/stop, status text change).
- **SC-004**: Discovery service state changes within 2 seconds of toggling Receive Mode.
- **SC-005**: Quick Save preference persists correctly across 100% of app restarts.
- **SC-005a**: Receive Mode state persists correctly across 100% of app restarts (defaults to OFF on fresh install).
- **SC-006**: HistoryView loads and displays transfer records within 1 second of opening.
- **SC-007**: Users can distinguish sent from received transfers at a glance via directional icons.
- **SC-008**: 95% of users can successfully enable Receive Mode on first attempt without guidance.

## Assumptions

- The device has a valid network connection when displaying IP address (handled gracefully when not connected).
- TransferHistory data already exists in the Drift database from previous feature implementations.
- Discovery service (mDNS) is already implemented and can be controlled programmatically.
- File server is already implemented and can be started/stopped based on Receive Mode toggle.
- Device info provider already exists for retrieving avatar, alias, IP, and port information.