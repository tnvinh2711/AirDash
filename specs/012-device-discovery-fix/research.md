# Research: Device Discovery Bug Fixes

**Feature**: 012-device-discovery-fix  
**Date**: 2024-12-08

## Research Topics

### 1. Scan Timeout Strategy

**Decision**: Add a `_scanTimeoutTimer` that fires after 5 seconds to set `isScanning = false`

**Rationale**:
- mDNS discovery events arrive within 1-3 seconds on typical networks
- 5 seconds provides buffer for slower networks while ensuring responsive UX
- Timer-based approach matches existing `_stalenessTimer` pattern in the codebase

**Alternatives Considered**:
- **Event-based completion**: Wait for a "discovery complete" event from Bonsoir
  - Rejected: Bonsoir doesn't emit a completion event for continuous discovery
- **Count-based completion**: Stop after N devices found
  - Rejected: Cannot predict how many devices exist on network
- **Immediate stop after first device**: Stop scanning once any device found
  - Rejected: Would miss other devices on network

**Implementation**:
```dart
Timer? _scanTimeoutTimer;
static const _scanTimeout = Duration(seconds: 5);

Future<void> startScan() async {
  // ... existing code ...
  _startScanTimeoutTimer();
}

void _startScanTimeoutTimer() {
  _scanTimeoutTimer?.cancel();
  _scanTimeoutTimer = Timer(_scanTimeout, () {
    // Mark scan as complete but keep discovery running in background
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(isScanning: false));
    }
  });
}
```

---

### 2. Grace Period for Device Removal

**Decision**: On `DeviceLostEvent`, delay removal by 30 seconds instead of removing immediately

**Rationale**:
- mDNS services can temporarily "disappear" due to network conditions
- Real device shutdown should be confirmed by staleness check
- 30 seconds provides reasonable grace while not keeping truly-gone devices too long

**Alternatives Considered**:
- **Ignore DeviceLostEvent entirely**: Only use staleness timer
  - Rejected: Would keep devices for full 2 minutes even after confirmed departure
- **Mark as "offline" visually**: Show grayed-out device
  - Rejected: Adds UI complexity for edge case; simpler to just delay removal
- **Reconfirm with HTTP ping**: Verify device is truly gone
  - Rejected: Adds network requests; device may be shutting down and not respond anyway

**Implementation**:
```dart
final Map<String, Timer> _pendingRemovalTimers = {};
static const _removalGracePeriod = Duration(seconds: 30);

void _handleDeviceLostEvent(String serviceInstanceName) {
  // Cancel any existing timer for this device
  _pendingRemovalTimers[serviceInstanceName]?.cancel();
  
  // Start grace period timer
  _pendingRemovalTimers[serviceInstanceName] = Timer(_removalGracePeriod, () {
    _actuallyRemoveDevice(serviceInstanceName);
    _pendingRemovalTimers.remove(serviceInstanceName);
  });
}

void _cancelPendingRemoval(String serviceInstanceName) {
  _pendingRemovalTimers[serviceInstanceName]?.cancel();
  _pendingRemovalTimers.remove(serviceInstanceName);
}
```

---

### 3. Interaction Between Timeout and Continuous Discovery

**Decision**: Scan timeout only controls UI state (`isScanning`); mDNS discovery continues in background

**Rationale**:
- Users expect refresh button to become available after short time
- Discovery should still detect new devices that appear later
- Separating UI state from actual discovery provides best UX

**Implementation Notes**:
- `isScanning = true` only during initial 5-second scan period
- Discovery events still processed after timeout (just without loading indicator)
- Refresh button restarts the 5-second timeout (and shows loading again)

---

## Existing Code Analysis

### Current Timer Usage in DiscoveryController

```dart
// Line 22-25: Existing staleness timer pattern
Timer? _stalenessTimer;
static const _stalenessCheckInterval = Duration(seconds: 30);
static const _stalenessTimeout = Duration(seconds: 120);
```

The new timers follow the same pattern for consistency.

### Current DeviceLostEvent Handling

```dart
// Line 132-133: Current immediate removal
case DeviceLostEvent(:final serviceInstanceName):
  _removeDevice(serviceInstanceName);
```

This will be changed to call `_scheduleDeviceRemoval()` instead.

---

## Summary of Changes

| Change | Location | Lines Changed |
|--------|----------|---------------|
| Add `_scanTimeoutTimer` | `discovery_controller.dart` | +15 |
| Add `_pendingRemovalTimers` map | `discovery_controller.dart` | +3 |
| Add grace period logic | `discovery_controller.dart` | +20 |
| Cancel pending removal on re-discovery | `discovery_controller.dart` | +5 |
| Update tests | `discovery_controller_test.dart` | +20 |
| **Total** | | **~65 lines** |

