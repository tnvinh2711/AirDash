# Quickstart: Device Discovery

**Feature**: 004-device-discovery | **Date**: 2025-12-06

## Prerequisites

- Flutter SDK via FVM (stable channel)
- Project initialized with `fvm flutter pub get`
- iOS: Xcode with Bonjour entitlements configured
- Android: Minimum SDK 21+

## Setup Steps

### 1. Install Dependencies

```bash
# Add bonsoir for mDNS discovery
fvm flutter pub add bonsoir

# Add device_info_plus for local device detection
fvm flutter pub add device_info_plus
```

### 2. Platform Configuration

#### iOS (ios/Runner/Info.plist)

Add Bonjour services declaration:

```xml
<key>NSBonjourServices</key>
<array>
  <string>_flux._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>FLUX needs local network access to discover nearby devices for file transfer.</string>
```

#### macOS (macos/Runner/DebugProfile.entitlements & Release.entitlements)

Add network entitlements:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

#### Android

No additional configuration needed (NSD supported from API 21).

### 3. Run Code Generation

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

## Usage Examples

### Start Discovery

```dart
final controller = ref.read(discoveryControllerProvider.notifier);

// Start broadcasting presence
await controller.startBroadcast();

// Start scanning for devices
await controller.startScan();
```

### Watch Discovery State

```dart
final state = ref.watch(discoveryControllerProvider);

state.when(
  data: (discovery) {
    if (discovery.isScanning) {
      // Show scanning indicator
    }
    for (final device in discovery.devices) {
      print('Found: ${device.alias} at ${device.ip}:${device.port}');
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Manual Refresh

```dart
await ref.read(discoveryControllerProvider.notifier).refresh();
```

### Stop Discovery

```dart
await controller.stopScan();
await controller.stopBroadcast();
```

## Testing

### Unit Test Pattern (Mocked Repository)

```dart
class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  late MockDiscoveryRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockDiscoveryRepository();
    container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  test('startScan updates isScanning state', () async {
    when(() => mockRepo.startScan()).thenAnswer(
      (_) => Stream.empty(),
    );

    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.startScan();

    final state = container.read(discoveryControllerProvider).value!;
    expect(state.isScanning, isTrue);
  });
}
```

## Common Commands

| Command | Description |
|---------|-------------|
| `fvm flutter pub get` | Install dependencies |
| `fvm flutter pub run build_runner build` | Generate Freezed/Riverpod code |
| `fvm flutter test test/features/discovery/` | Run discovery tests |
| `fvm flutter analyze` | Check for lint issues |

## Troubleshooting

### Devices not discovered on iOS

- Verify `NSBonjourServices` includes `_flux._tcp`
- Verify `NSLocalNetworkUsageDescription` is present
- Grant local network permission when prompted

### Devices not discovered on macOS

- Verify network entitlements in both Debug and Release profiles
- Check firewall settings allow mDNS traffic (port 5353)

### Own device appears in list

- Verify `ownServiceInstanceName` is correctly captured after broadcast starts
- Check filtering logic in discovery event handler

