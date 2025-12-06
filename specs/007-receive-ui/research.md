# Research: Receive Tab UI

**Feature**: 007-receive-ui  
**Date**: 2025-12-06

## Research Questions

### 1. How to retrieve the device's local IP address?

**Decision**: Use `NetworkInterface.list()` from `dart:io` to enumerate network interfaces and find the primary IPv4 address.

**Rationale**:
- Native Dart API, no additional dependencies needed
- Works across all platforms (Android, iOS, macOS, Windows, Linux)
- Can filter for WiFi/Ethernet interfaces and exclude loopback

**Implementation Pattern**:
```dart
Future<String?> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  );
  
  for (final interface in interfaces) {
    // Skip loopback and virtual interfaces
    if (interface.name.startsWith('lo') || 
        interface.name.startsWith('docker') ||
        interface.name.startsWith('veth')) {
      continue;
    }
    
    for (final addr in interface.addresses) {
      if (!addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return null; // No network connection
}
```

### 2. How to persist Receive Mode and Quick Save settings?

**Decision**: Use existing `SettingsRepository` with Drift `SettingsTable` (key-value store).

**Rationale**:
- Consistent with existing settings persistence (theme, alias, port)
- Already implemented in Feature 003 (local-storage)
- Supports reactive updates via Drift streams

**Implementation Pattern**:
```dart
// Add to SettingKeys
static const receiveMode = 'receive_mode';
static const quickSave = 'quick_save';

// Add to SettingsRepository
Future<bool> getReceiveMode() async {
  final value = await getSetting(SettingKeys.receiveMode);
  return value == 'true';
}

Future<void> setReceiveMode(bool enabled) =>
    setSetting(SettingKeys.receiveMode, enabled.toString());
```

### 3. How to implement pulse animation on avatar?

**Decision**: Use `AnimatedContainer` with `AnimationController` for a pulsing scale/opacity effect.

**Rationale**:
- Native Flutter animation APIs
- Smooth 60fps performance
- Can be controlled via Receive Mode state

**Implementation Pattern**:
```dart
class PulsingAvatar extends StatefulWidget {
  final bool isActive;
  final Widget child;
  
  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(PulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }
}
```

### 4. How to add the /history route to go_router?

**Decision**: Add a nested route under the Receive branch in `StatefulShellRoute`.

**Rationale**:
- Maintains tab state when navigating to history
- Uses standard go_router navigation with back button
- Follows existing routing patterns

**Implementation Pattern**:
```dart
// In routes.dart
static const history = '/receive/history';

// In app_router.dart - Receive branch
StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.receive,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ReceiveScreen(),
      ),
      routes: [
        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
  ],
),
```

### 5. How to copy IP address to clipboard with feedback?

**Decision**: Use `Clipboard.setData()` from `flutter/services.dart` with `ScaffoldMessenger` for feedback.

**Rationale**:
- Native Flutter API, works on all platforms
- ScaffoldMessenger provides consistent snackbar feedback
- Simple one-tap interaction

**Implementation Pattern**:
```dart
Future<void> _copyIpAddress(BuildContext context, String ip) async {
  await Clipboard.setData(ClipboardData(text: ip));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IP address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
```

### 6. How to handle "no network" state for IP address?

**Decision**: Display "Not Connected" placeholder when IP is null.

**Rationale**:
- Clear user feedback about network status
- Graceful degradation without crashes
- Consistent with edge case in spec

**Implementation Pattern**:
```dart
Text(
  ipAddress ?? 'Not Connected',
  style: ipAddress != null 
    ? theme.textTheme.bodyLarge 
    : theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
)
```

## Existing Code to Reuse

| Component | Location | Usage |
|-----------|----------|-------|
| `ServerController` | `lib/src/features/receive/application/server_controller.dart` | Start/stop server, manage broadcast |
| `DeviceInfoProvider` | `lib/src/core/providers/device_info_provider.dart` | Get alias, device type, OS |
| `SettingsRepository` | `lib/src/features/settings/data/settings_repository.dart` | Persist settings |
| `HistoryRepository` | `lib/src/features/history/data/history_repository.dart` | Fetch transfer history |
| `historyStreamProvider` | `lib/src/features/history/application/history_provider.dart` | Watch history updates |
| `TransferHistoryEntry` | `lib/src/features/history/domain/transfer_history_entry.dart` | History data model |
| `LocalDeviceInfo` | `lib/src/features/discovery/domain/local_device_info.dart` | Device info model |
| `ServerState` | `lib/src/features/receive/domain/server_state.dart` | Server state model |

## New Code Required

| Component | Location | Purpose |
|-----------|----------|---------|
| `getLocalIpAddress()` | `DeviceInfoProvider` | Retrieve device IP |
| `ReceiveSettings` | `lib/src/features/receive/domain/receive_settings.dart` | Settings model |
| `receiveSettingsProvider` | `lib/src/features/receive/application/receive_settings_provider.dart` | Settings state |
| `IdentityCard` | `lib/src/features/receive/presentation/widgets/identity_card.dart` | Identity display widget |
| `ServerToggle` | `lib/src/features/receive/presentation/widgets/server_toggle.dart` | Receive Mode toggle |
| `QuickSaveSwitch` | `lib/src/features/receive/presentation/widgets/quick_save_switch.dart` | Quick Save toggle |
| `PulsingAvatar` | `lib/src/features/receive/presentation/widgets/pulsing_avatar.dart` | Animated avatar |
| `HistoryScreen` | `lib/src/features/receive/presentation/history_screen.dart` | Full-screen history |
| `/history` route | `app_router.dart` | Navigation route |

## Dependencies

No new dependencies required. All functionality uses existing packages:
- `flutter_riverpod` - State management
- `drift` - Settings persistence
- `go_router` - Navigation
- `device_info_plus` - Device info (already used)
- `dart:io` - NetworkInterface for IP address
- `flutter/services.dart` - Clipboard

