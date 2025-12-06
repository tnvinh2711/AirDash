# Feature Specification: Device Discovery Logic

**Feature Branch**: `004-device-discovery`  
**Created**: 2025-12-06  
**Status**: Draft  
**Input**: User description: "Device Discovery Logic (Backend) - Goal: Implement the logic to broadcast presence and find other devices on the LAN. Requirements: Data Layer - Install bonsoir (or nsd), Create DiscoveryRepository with startBroadcast, stopBroadcast, startScan, stopScan methods. Application Layer - Define Device model using Freezed, Create DiscoveryController (AsyncNotifier) with state management. Testing - Unit Test DiscoveryController by mocking DiscoveryRepository."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover Other Devices on LAN (Priority: P1)

A user opens the app and wants to see all other AirDash/FLUX devices available on their local network. The app automatically scans the network and displays discovered devices, allowing the user to select one for file transfer.

**Why this priority**: This is the core value proposition - users cannot transfer files without first discovering other devices. This enables the fundamental peer-to-peer connection that makes the app useful.

**Independent Test**: Can be fully tested by launching the app on two devices on the same network, verifying each device appears in the other's discovery list, and confirming device information (alias, IP) is displayed correctly.

**Acceptance Scenarios**:

1. **Given** the app is launched on a network with other AirDash devices, **When** the discovery scan starts, **Then** all compatible devices on the LAN appear in the device list within 5 seconds
2. **Given** the app is actively scanning, **When** a new device joins the network, **Then** the new device appears in the list without manual refresh
3. **Given** the discovery list shows devices, **When** a device leaves the network, **Then** that device is removed from the list automatically

---

### User Story 2 - Broadcast Own Presence (Priority: P1)

A user's device automatically broadcasts its presence when the app is running, allowing other devices on the network to discover it.

**Why this priority**: Broadcasting is equally critical as discovery - without broadcasting, other devices cannot find this device. Both sides of the connection need to work for file transfer.

**Independent Test**: Can be tested by running the app on Device A, then using a separate mDNS browser tool (or another AirDash instance) to verify Device A's service is visible on the network with correct metadata.

**Acceptance Scenarios**:

1. **Given** the app starts, **When** the broadcast service initializes, **Then** the device is discoverable via mDNS within 2 seconds
2. **Given** the device is broadcasting, **When** the device alias or port changes, **Then** the broadcast updates to reflect new information
3. **Given** the app is closed or backgrounded, **When** broadcasting stops, **Then** other devices no longer see this device in their discovery lists

---

### User Story 3 - Manual Refresh Discovery (Priority: P2)

A user can manually refresh the device list if they believe a device should be visible but is not appearing, or to force an immediate rescan.

**Why this priority**: While automatic discovery should work most of the time, network conditions may require manual intervention. This provides user control and troubleshooting capability.

**Independent Test**: Can be tested by triggering the refresh action and verifying the scan restarts, the list updates, and any stale entries are cleared.

**Acceptance Scenarios**:

1. **Given** the discovery list is displayed, **When** the user triggers a refresh action, **Then** the scanner restarts and the device list is updated
2. **Given** a scan is in progress, **When** the user triggers refresh, **Then** the current scan stops and a new scan begins
3. **Given** stale device entries exist, **When** refresh completes, **Then** devices no longer on the network are removed

---

### User Story 4 - Filter Own Device from List (Priority: P2)

The user's own device should not appear in the discovery list, as connecting to oneself is not a valid use case.

**Why this priority**: This is a UX polish item that prevents confusion. Users should only see valid transfer targets.

**Independent Test**: Can be tested by verifying the current device's IP address is filtered from the discovery results.

**Acceptance Scenarios**:

1. **Given** the device is scanning and broadcasting simultaneously, **When** the discovery list is displayed, **Then** the user's own device does not appear in the list
2. **Given** the device has multiple network interfaces, **When** any local IP is detected in discovery, **Then** all local IPs are filtered from results

---

### Edge Cases

- What happens when no other devices are found on the network? → Display empty state with helpful message
- How does system handle rapid network changes (WiFi switching)? → Restart discovery gracefully, clear stale entries
- What happens when mDNS service fails to start? → Surface error to user, allow retry
- How does system handle duplicate device announcements? → Deduplicate by unique device ID
- What happens when device alias contains special characters? → Properly encode/decode in mDNS TXT records

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST broadcast device presence using mDNS/DNS-SD protocol on the local network
- **FR-002**: System MUST discover other compatible devices on the local network using mDNS/DNS-SD
- **FR-003**: System MUST automatically start broadcasting when the app launches
- **FR-004**: System MUST automatically start scanning when the discovery screen is active
- **FR-005**: System MUST stop broadcasting when the app is closed or backgrounded
- **FR-006**: System MUST stop scanning when the discovery screen is no longer active
- **FR-007**: System MUST filter out the current device from discovery results
- **FR-008**: System MUST support manual refresh to restart the discovery scan
- **FR-009**: System MUST expose discovery state including: scanning status, device list, and errors
- **FR-010**: System MUST include device metadata in broadcast: IP address, port, alias, device type, OS
- **FR-011**: System MUST automatically update the device list when devices join or leave the network
- **FR-012**: System MUST handle mDNS service failures gracefully with user-facing error messages

### Key Entities

- **Device**: Represents a discovered peer on the network
  - Service Instance Name: mDNS service instance identifier (e.g., "MyMacBook._airdash._tcp.local")
  - IP address: Network address for connection
  - Port: Service port for file transfer
  - Alias: Human-readable device name (user-configured or hostname)
  - Device Type: Category of device (phone, tablet, desktop, laptop)
  - Operating System: Platform identifier (iOS, Android, macOS, Windows, Linux)
  - **Unique Key**: Combination of Service Instance Name + IP address (for deduplication)

- **DiscoveryState**: Represents the current state of the discovery system
  - isScanning: Whether active scanning is in progress
  - devices: List of currently discovered devices
  - error: Optional error message if discovery fails

- **Device Lifecycle**: Devices are removed from the list when:
  - mDNS goodbye packet is received (immediate removal), OR
  - No announcement received for 30 seconds (staleness timeout)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Devices on the same LAN discover each other within 5 seconds of both apps being active
- **SC-002**: Device list updates automatically when a new device joins the network (no manual refresh required)
- **SC-003**: Own device is never displayed in the discovery list
- **SC-004**: Manual refresh action completes and updates the list within 3 seconds
- **SC-005**: Discovery works reliably across WiFi network switches without app restart
- **SC-006**: Users can clearly see when scanning is in progress vs. completed
- **SC-007**: Error states are communicated clearly when mDNS service is unavailable

## Clarifications

### Session 2025-12-06

- Q: How long should a device remain visible after it stops responding before automatic removal? → A: mDNS goodbye packet triggers immediate removal; additionally, devices with no announcements for 30 seconds are considered stale and removed.
- Q: How should devices be uniquely identified for deduplication? → A: Combination of mDNS service instance name + IP address (standard Bonjour/mDNS pattern).

## Assumptions

- The app will use the `bonsoir` Flutter package for mDNS service discovery (industry-standard for Flutter)
- All devices will use the same mDNS service type (e.g., `_airdash._tcp`) for discovery
- Device alias defaults to the system hostname if not configured by user
- Port number is determined by the file transfer service configuration
- Network environment allows mDNS multicast traffic (standard for most home/office networks)

