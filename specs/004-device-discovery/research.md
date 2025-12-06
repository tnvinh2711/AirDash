# Research: Device Discovery Logic

**Feature**: 004-device-discovery | **Date**: 2025-12-06

## Research Tasks

### 1. mDNS Package Selection: bonsoir

**Decision**: Use `bonsoir` package (version ^6.0.1)

**Rationale**:
- Constitution mandates `bonsoir` for device discovery
- Supports all target platforms: Android, iOS, macOS, Windows, Linux
- Based on native implementations: Android NSD and Apple Bonjour
- Active maintenance (published 2025-07-26)
- Well-documented API with event streams

**Alternatives Considered**:
- `nsd_platform_interface` - Less maintained, fewer platform support
- `multicast_dns` - Lower-level, requires manual implementation

**API Pattern**:
```dart
// Broadcasting
BonsoirBroadcast broadcast = BonsoirBroadcast(service: service);
await broadcast.initialize();
await broadcast.start();
await broadcast.stop();

// Discovery
BonsoirDiscovery discovery = BonsoirDiscovery(type: type);
await discovery.initialize();
discovery.eventStream!.listen((event) { ... });
await discovery.start();
await discovery.stop();
```

---

### 2. Service Type Naming Convention

**Decision**: Use `_flux._tcp` as the mDNS service type

**Rationale**:
- Follows DNS-SD naming convention: `_ServiceName._Protocol`
- Uses app name "flux" for uniqueness on LAN
- TCP protocol aligns with planned HTTP-based file transfer

**Alternatives Considered**:
- `_airdash._tcp` - Previous project name, less aligned with current branding
- `_filetransfer._tcp` - Too generic, may conflict with other apps

---

### 3. TXT Record Attributes for Device Metadata

**Decision**: Include the following TXT record attributes:

| Key | Value | Example |
|-----|-------|---------|
| `alias` | User-configured or hostname | "John's MacBook" |
| `deviceType` | phone\|tablet\|desktop\|laptop | "desktop" |
| `os` | iOS\|Android\|macOS\|Windows\|Linux | "macOS" |
| `version` | App protocol version | "1" |

**Rationale**:
- TXT records are standard mDNS metadata mechanism
- Keys kept short to minimize packet size
- `version` enables future protocol compatibility checks

---

### 4. Device Self-Filtering Strategy

**Decision**: Filter by comparing discovered service instance name against own device's broadcast service instance name

**Rationale**:
- Service instance name is unique per broadcast
- More reliable than IP comparison (device may have multiple IPs)
- bonsoir provides access to own service instance name after broadcast starts

**Implementation**:
```dart
// Own service instance name stored when broadcast starts
final ownServiceName = broadcast.service.name;

// Filter during discovery
if (event.service.name != ownServiceName) {
  // Add to discovered devices
}
```

---

### 5. Staleness Detection Implementation

**Decision**: Implement 30-second timeout using timestamp tracking

**Rationale**:
- mDNS goodbye packets provide immediate removal
- Timestamp tracking handles cases where goodbye is not received (network issues)
- 30 seconds balances responsiveness with stability

**Implementation Approach**:
- Store `lastSeen: DateTime` for each discovered device
- On each mDNS event, update timestamp
- Periodic timer (every 10 seconds) prunes devices older than 30 seconds
- Stop timer when discovery stops

---

### 6. AsyncNotifier Pattern for DiscoveryController

**Decision**: Use `AsyncNotifier<DiscoveryState>` with Riverpod generator

**Rationale**:
- Constitution mandates Riverpod with riverpod_generator
- AsyncNotifier handles async initialization cleanly
- State object (DiscoveryState) can represent loading/data/error states

**Pattern**:
```dart
@riverpod
class DiscoveryController extends _$DiscoveryController {
  @override
  Future<DiscoveryState> build() async {
    return DiscoveryState.initial();
  }
  
  Future<void> startScan() async { ... }
  Future<void> stopScan() async { ... }
  Future<void> refresh() async { ... }
}
```

---

### 7. Local Device Info Provider

**Decision**: Create `DeviceInfoProvider` using `device_info_plus` package

**Rationale**:
- Need device type detection (phone/tablet/desktop/laptop)
- Need OS detection for TXT record
- Need hostname fallback for device alias
- `device_info_plus` is the standard Flutter solution

**New Dependency Required**: `device_info_plus: ^10.1.0`

---

## Summary

All technical unknowns resolved. Key decisions:
- bonsoir ^6.0.1 for mDNS
- device_info_plus ^10.1.0 for local device info
- Service type: `_flux._tcp`
- Self-filtering via service instance name comparison
- 30-second staleness timeout with timestamp tracking
- AsyncNotifier pattern for state management

