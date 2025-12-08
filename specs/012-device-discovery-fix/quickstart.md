# Quickstart: Device Discovery Bug Fixes

**Feature**: 012-device-discovery-fix  
**Estimated Time**: 30 minutes

## Prerequisites

- Flutter SDK via FVM (`fvm flutter --version`)
- Project dependencies installed (`fvm flutter pub get`)
- Run code generation (`dart run build_runner build`)

## Implementation Steps

### Step 1: Add Scan Timeout Timer (Bug 1 Fix)

**File**: `lib/src/features/discovery/application/discovery_controller.dart`

1. Add timer field and constant (near line 22):
```dart
Timer? _scanTimeoutTimer;
static const _scanTimeout = Duration(seconds: 5);
```

2. Add helper methods:
```dart
void _startScanTimeoutTimer() {
  _scanTimeoutTimer?.cancel();
  _scanTimeoutTimer = Timer(_scanTimeout, _onScanTimeout);
}

void _onScanTimeout() {
  final currentState = state.valueOrNull;
  if (currentState != null && currentState.isScanning) {
    state = AsyncData(currentState.copyWith(isScanning: false));
  }
}
```

3. Call `_startScanTimeoutTimer()` at end of `startScan()` method (after line 64)

4. Cancel timer in `_cleanup()` method:
```dart
void _cleanup() {
  _scanSubscription?.cancel();
  _scanTimeoutTimer?.cancel();  // ADD THIS
  _stalenessTimer?.cancel();
}
```

### Step 2: Add Grace Period for Device Removal (Bug 2 Fix)

**File**: `lib/src/features/discovery/application/discovery_controller.dart`

1. Add pending removal tracking (near line 22):
```dart
final Map<String, Timer> _pendingRemovalTimers = {};
static const _removalGracePeriod = Duration(seconds: 30);
```

2. Modify `_handleDiscoveryEvent` to use grace period (around line 132):
```dart
case DeviceLostEvent(:final serviceInstanceName):
  _scheduleDeviceRemoval(serviceInstanceName);  // CHANGED from _removeDevice
```

3. Add new methods:
```dart
void _scheduleDeviceRemoval(String serviceInstanceName) {
  _pendingRemovalTimers[serviceInstanceName]?.cancel();
  _pendingRemovalTimers[serviceInstanceName] = Timer(
    _removalGracePeriod,
    () => _executeDeviceRemoval(serviceInstanceName),
  );
}

void _executeDeviceRemoval(String serviceInstanceName) {
  _removeDevice(serviceInstanceName);
  _pendingRemovalTimers.remove(serviceInstanceName);
}

void _cancelPendingRemoval(String serviceInstanceName) {
  _pendingRemovalTimers[serviceInstanceName]?.cancel();
  _pendingRemovalTimers.remove(serviceInstanceName);
}
```

4. Cancel pending removal when device is re-discovered. In `_addOrUpdateDevice()`, add:
```dart
// Cancel any pending removal for this device
_cancelPendingRemoval(device.serviceInstanceName);
```

5. Clean up all pending timers in `_cleanup()`:
```dart
void _cleanup() {
  _scanSubscription?.cancel();
  _scanTimeoutTimer?.cancel();
  _stalenessTimer?.cancel();
  for (final timer in _pendingRemovalTimers.values) {
    timer.cancel();
  }
  _pendingRemovalTimers.clear();
}
```

## Verification

### Manual Testing

1. **Refresh Button Test**:
   - Open Send screen
   - Tap refresh button
   - Observe: Loading indicator appears for ~5 seconds, then refresh icon returns
   - Tap refresh again - should work immediately

2. **Device Persistence Test**:
   - Start app on Device A (sender)
   - Start app on Device B (receiver) - should appear in list
   - Wait 2+ minutes - Device B should remain visible
   - Stop Device B's server - Device B should disappear after ~30 seconds

### Automated Testing

```bash
fvm flutter test test/features/discovery/
```

## Success Criteria Checklist

- [ ] Refresh button returns to idle within 10 seconds
- [ ] Devices remain visible for at least 2 minutes
- [ ] Devices survive brief mDNS interruptions (30s grace period)
- [ ] No duplicate device entries
- [ ] All existing discovery tests pass

