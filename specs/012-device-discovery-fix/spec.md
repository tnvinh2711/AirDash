# Feature Specification: Device Discovery Bug Fixes

**Feature Branch**: `012-device-discovery-fix`
**Created**: 2024-12-08
**Status**: Draft
**Input**: User description: "investigate why nearby devices only show a short period of time, and refresh button always loading in sending screen"

## Problem Analysis

### Bug 1: Refresh Button Always Loading
The refresh button in the Send screen's device grid shows a `CircularProgressIndicator` indefinitely because `isScanning` is set to `true` when `startScan()` is called but never automatically set back to `false`. The mDNS discovery runs continuously until manually stopped.

**Root Cause**: `DiscoveryController.startScan()` starts continuous mDNS scanning but has no automatic timeout or completion mechanism.

### Bug 2: Devices Disappear After Short Time
Discovered devices disappear from the list due to:
1. **DeviceLostEvent**: mDNS library fires `BonsoirDiscoveryServiceLostEvent` when it loses track of a service (cache timeout, network hiccup, broadcaster restart)
2. **Staleness Pruning**: Timer removes devices not seen in 120 seconds

**Root Cause**: The `_removeDevice()` method immediately removes devices on `DeviceLostEvent` without any grace period or reconfirmation.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Device Discovery (Priority: P1 🎯 MVP)

As a sender, I want to see nearby devices remain visible in the list as long as they are available, so I can select a device to send files without devices disappearing unexpectedly.

**Why this priority**: Core functionality - users cannot send files if target devices keep disappearing

**Independent Test**: Open send screen on Device A, ensure Device B is running and visible. Device B should remain visible for at least 5 minutes without disappearing (unless Device B actually stops the server).

**Acceptance Scenarios**:

1. **Given** Device B is broadcasting on the network, **When** I view the Send screen on Device A, **Then** Device B appears and remains visible as long as it's broadcasting
2. **Given** Device B is visible in my device list, **When** Device B experiences a temporary mDNS hiccup, **Then** Device B remains visible (with grace period) rather than disappearing immediately
3. **Given** Device B stops broadcasting, **When** 30+ seconds pass, **Then** Device B is removed from the list

---

### User Story 2 - Responsive Refresh Button (Priority: P1 🎯 MVP)

As a sender, I want the refresh button to show loading only while actively scanning and return to normal after a reasonable time, so I can manually trigger a rescan when needed.

**Why this priority**: Core UX - infinite loading state confuses users and prevents manual refresh

**Independent Test**: Tap refresh button, observe loading indicator for 5-10 seconds, then see it return to refresh icon.

**Acceptance Scenarios**:

1. **Given** the Send screen is open, **When** I tap the refresh button, **Then** it shows loading for a defined scan period (e.g., 5 seconds) then returns to idle
2. **Given** scan is in progress (loading shown), **When** scan completes, **Then** the refresh icon is shown and tappable
3. **Given** refresh was already tapped, **When** I tap refresh again while scanning, **Then** no action (debounce) or restart scan

---

### Edge Cases

- What happens when network changes mid-scan? → Restart discovery automatically
- What happens when no devices are found after refresh? → Show empty state with "No devices found" message
- What happens when a device restarts its server (port changes)? → Update device info, don't duplicate

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST complete a scan cycle within a defined timeout (5-10 seconds) and set `isScanning` to `false`
- **FR-002**: System MUST NOT immediately remove devices on `DeviceLostEvent`; apply a grace period (e.g., 30 seconds)
- **FR-003**: System MUST keep discovered devices visible for at least 2 minutes if they were successfully resolved
- **FR-004**: System MUST update existing device entries when the same device re-broadcasts (no duplicates)
- **FR-005**: Refresh button MUST be tappable when not scanning (show refresh icon, not loading spinner)
- **FR-006**: System MUST log discovery events for debugging (already exists, verify retained)

### Key Entities *(no new entities)*

Existing entities remain unchanged:
- **Device**: Discovered device with IP, port, alias, deviceType, lastSeen
- **DiscoveryState**: isScanning, isBroadcasting, devices list

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Devices remain visible for at least 2 minutes after initial discovery (unless server stops)
- **SC-002**: Refresh button returns to idle state within 10 seconds of being tapped
- **SC-003**: Devices that temporarily lose mDNS broadcast but return within 30 seconds are not removed
- **SC-004**: No duplicate device entries for the same IP address
- **SC-005**: Manual refresh can be triggered at any time when not currently scanning
