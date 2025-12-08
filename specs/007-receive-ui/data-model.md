# Data Model: Receive Tab UI

**Feature**: 007-receive-ui  
**Date**: 2025-12-06

## Domain Models

### ReceiveSettings (NEW)

User preferences for the Receive tab functionality.

```dart
// lib/src/features/receive/domain/receive_settings.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receive_settings.freezed.dart';

/// User settings for receive functionality.
@freezed
class ReceiveSettings with _$ReceiveSettings {
  const factory ReceiveSettings({
    /// Whether Receive Mode is enabled (device discoverable).
    @Default(false) bool receiveModeEnabled,
    
    /// Whether Quick Save is enabled (auto-accept transfers).
    @Default(false) bool quickSaveEnabled,
  }) = _ReceiveSettings;
  
  /// Default settings for fresh install.
  factory ReceiveSettings.defaults() => const ReceiveSettings();
}
```

### DeviceIdentity (NEW)

Complete device identity information for display in Identity Card.

```dart
// lib/src/features/receive/domain/device_identity.dart
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_identity.freezed.dart';

/// Device identity information for the Identity Card.
@freezed
class DeviceIdentity with _$DeviceIdentity {
  const factory DeviceIdentity({
    /// Device alias (friendly name).
    required String alias,
    
    /// Device type (phone, tablet, laptop, desktop).
    required DeviceType deviceType,
    
    /// Operating system name.
    required String os,
    
    /// Local IP address (null if not connected).
    String? ipAddress,
    
    /// Server port number.
    required int port,
  }) = _DeviceIdentity;
}
```

## Existing Models (Reused)

### TransferHistoryEntry

Already exists at `lib/src/features/history/domain/transfer_history_entry.dart`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Auto-incremented unique ID |
| `transferId` | `String` | UUID of transfer session |
| `fileName` | `String` | Name of transferred file |
| `fileCount` | `int` | Number of files (>1 for folders) |
| `totalSize` | `int` | Total size in bytes |
| `fileType` | `String` | File type identifier |
| `timestamp` | `DateTime` | When transfer completed |
| `status` | `TransferStatus` | completed/failed/cancelled |
| `direction` | `TransferDirection` | sent/received |
| `remoteDeviceAlias` | `String` | Name of other device |

### ServerState

Already exists at `lib/src/features/receive/domain/server_state.dart`.

| Field | Type | Description |
|-------|------|-------------|
| `isRunning` | `bool` | Whether HTTP server is running |
| `port` | `int?` | Port server is bound to |
| `isBroadcasting` | `bool` | Whether mDNS broadcast is active |
| `activeSession` | `TransferSession?` | Current transfer session |
| `transferProgress` | `TransferProgress?` | Progress of active transfer |
| `error` | `String?` | Last error message |
| `lastCompleted` | `CompletedTransferInfo?` | Last completed transfer info |

### LocalDeviceInfo

Already exists at `lib/src/features/discovery/domain/local_device_info.dart`.

| Field | Type | Description |
|-------|------|-------------|
| `alias` | `String` | Device name |
| `deviceType` | `DeviceType` | Device category |
| `os` | `String` | Operating system |
| `port` | `int` | Server port |

## Settings Keys (Extension)

Add to existing `SettingKeys` in `lib/src/features/settings/data/settings_repository.dart`:

```dart
abstract class SettingKeys {
  // Existing keys
  static const theme = 'theme';
  static const alias = 'alias';
  static const port = 'port';
  
  // NEW keys for Feature 007
  static const receiveMode = 'receive_mode';
  static const quickSave = 'quick_save';
}
```

## Entity Relationships

```
┌─────────────────┐     ┌──────────────────┐
│ ReceiveSettings │     │  DeviceIdentity  │
├─────────────────┤     ├──────────────────┤
│ receiveModeEnabled    │ alias            │
│ quickSaveEnabled │    │ deviceType       │
└────────┬────────┘     │ os               │
         │              │ ipAddress        │
         │              │ port             │
         │              └────────┬─────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│            ReceiveScreen                │
├─────────────────────────────────────────┤
│ - IdentityCard (DeviceIdentity)         │
│ - ServerToggle (ReceiveSettings)        │
│ - QuickSaveSwitch (ReceiveSettings)     │
│ - HistoryButton → HistoryScreen         │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            HistoryScreen                │
├─────────────────────────────────────────┤
│ - List<TransferHistoryEntry>            │
│ - Empty state when no records           │
└─────────────────────────────────────────┘
```

## State Flow

```
User toggles Receive Mode ON
         │
         ▼
┌─────────────────────────────────────────┐
│ receiveSettingsProvider.setReceiveMode  │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┴────────────┐
    ▼                         ▼
┌───────────────┐    ┌────────────────────┐
│ Persist to DB │    │ ServerController   │
│ (SettingsRepo)│    │ .startServer()     │
└───────────────┘    └────────┬───────────┘
                              │
                 ┌────────────┴────────────┐
                 ▼                         ▼
        ┌────────────────┐    ┌────────────────────┐
        │ Start HTTP     │    │ Start mDNS         │
        │ Server         │    │ Broadcast          │
        └────────────────┘    └────────────────────┘
```

