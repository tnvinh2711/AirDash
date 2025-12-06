# Quickstart: Receive Tab UI

**Feature**: 007-receive-ui  
**Date**: 2025-12-06

## Manual Test Flow

### Prerequisites

1. Flutter SDK installed via FVM
2. Run `fvm flutter pub get`
3. Run `fvm flutter pub run build_runner build --delete-conflicting-outputs`

### Test 1: View Device Identity (US-1)

1. Launch the app: `fvm flutter run`
2. Navigate to the Receive tab (should be default)
3. **Verify**: Identity Card displays in center with:
   - Device avatar (icon based on device type)
   - Device alias (e.g., "MacBook Pro")
   - IP address (e.g., "192.168.1.100") or "Not Connected"
   - Port number (e.g., "8080")
4. Tap the IP address
5. **Verify**: Snackbar appears "IP address copied to clipboard"
6. Paste in another app to confirm clipboard content

### Test 2: Toggle Receive Mode (US-2)

1. From Receive tab, locate the "Receive Mode" toggle
2. **Verify**: Toggle is OFF by default (fresh install)
3. **Verify**: Status text shows "Offline"
4. **Verify**: Avatar is static (no animation)
5. Toggle Receive Mode ON
6. **Verify**: Pulse animation starts on avatar
7. **Verify**: Status text changes to "Ready"
8. **Verify**: Toggle responds within 500ms
9. Toggle Receive Mode OFF
10. **Verify**: Pulse animation stops
11. **Verify**: Status text changes to "Offline"

### Test 3: Receive Mode Persistence (FR-016a)

1. Toggle Receive Mode ON
2. Close the app completely (force quit)
3. Relaunch the app
4. **Verify**: Receive Mode is still ON
5. **Verify**: Pulse animation is active
6. Toggle Receive Mode OFF
7. Close and relaunch
8. **Verify**: Receive Mode is still OFF

### Test 4: Toggle Quick Save (US-3)

1. From Receive tab, locate the "Quick Save" toggle
2. **Verify**: Toggle is OFF by default
3. Toggle Quick Save ON
4. Close and relaunch the app
5. **Verify**: Quick Save is still ON
6. Toggle Quick Save OFF
7. Close and relaunch
8. **Verify**: Quick Save is still OFF

### Test 5: View Transfer History (US-4)

1. From Receive tab, tap the History button (top-right)
2. **Verify**: Full-screen HistoryView opens
3. **Verify**: Back button is visible in app bar
4. If no transfers exist:
   - **Verify**: Empty state message displayed
5. If transfers exist:
   - **Verify**: List shows transfer records
   - **Verify**: Sent transfers have upward arrow icon
   - **Verify**: Received transfers have downward arrow icon
   - **Verify**: Each item shows file name, date/time, status
6. Tap back button
7. **Verify**: Returns to Receive tab

### Test 6: Network Disconnection (Edge Case)

1. Disconnect from WiFi/network
2. Navigate to Receive tab
3. **Verify**: IP address shows "Not Connected" or similar
4. Reconnect to network
5. **Verify**: IP address updates to show actual IP

### Test 7: Performance Verification

1. Open Receive tab
2. **Verify**: Identity Card loads within 1 second (SC-001)
3. Toggle Receive Mode
4. **Verify**: Visual feedback within 500ms (SC-003)
5. Open HistoryView
6. **Verify**: History loads within 1 second (SC-006)

## Code Verification

### Run Tests

```bash
# Unit tests
fvm flutter test test/features/receive/

# All tests
fvm flutter test

# With coverage
fvm flutter test --coverage
```

### Run Linter

```bash
fvm flutter analyze
# Verify: 0 issues found
```

### Build Check

```bash
# Generate code
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Build for current platform
fvm flutter build apk --debug  # Android
fvm flutter build ios --debug  # iOS
fvm flutter build macos --debug  # macOS
```

## Expected File Changes

After implementation, these files should be modified or created:

### Modified Files
- `lib/src/core/providers/device_info_provider.dart` - Add `getLocalIpAddress()`
- `lib/src/core/routing/app_router.dart` - Add `/history` route
- `lib/src/core/routing/routes.dart` - Add `history` constant
- `lib/src/features/settings/data/settings_repository.dart` - Add receive/quickSave keys
- `lib/src/features/receive/presentation/receive_screen.dart` - New layout

### New Files
- `lib/src/features/receive/domain/receive_settings.dart`
- `lib/src/features/receive/domain/device_identity.dart`
- `lib/src/features/receive/application/receive_settings_provider.dart`
- `lib/src/features/receive/presentation/widgets/identity_card.dart`
- `lib/src/features/receive/presentation/widgets/server_toggle.dart`
- `lib/src/features/receive/presentation/widgets/quick_save_switch.dart`
- `lib/src/features/receive/presentation/widgets/pulsing_avatar.dart`
- `lib/src/features/receive/presentation/history_screen.dart`

