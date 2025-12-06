# Data Model: Device Discovery

**Feature**: 004-device-discovery | **Date**: 2025-12-06

## Entity Definitions

### Device

A discovered peer on the local network.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `serviceInstanceName` | `String` | Not Null | mDNS service instance identifier (e.g., "MyMacBook._flux._tcp.local") |
| `ip` | `String` | Not Null | IPv4 address for connection |
| `port` | `int` | Not Null, > 0 | Service port for file transfer |
| `alias` | `String` | Not Null | Human-readable device name |
| `deviceType` | `DeviceType` | Not Null | Category of device |
| `os` | `String` | Not Null | Platform identifier |
| `lastSeen` | `DateTime` | Not Null | Last mDNS announcement timestamp |

**Unique Key**: `serviceInstanceName` + `ip`

**Notes**:
- `lastSeen` used for staleness detection (30-second timeout)
- `alias` sourced from mDNS TXT record, defaults to hostname
- Device is immutable (Freezed); use `copyWith` for updates

---

### DeviceType (Enum)

Category of device based on form factor.

| Value | Description |
|-------|-------------|
| `phone` | Mobile phone (iOS/Android) |
| `tablet` | Tablet device (iPad/Android tablet) |
| `desktop` | Desktop computer (iMac, Windows PC) |
| `laptop` | Laptop computer (MacBook, notebook) |
| `unknown` | Unrecognized device type |

---

### DiscoveryState

State container for the discovery system.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `isScanning` | `bool` | Not Null | Whether active scanning is in progress |
| `isBroadcasting` | `bool` | Not Null | Whether broadcasting own presence |
| `devices` | `List<Device>` | Not Null | Currently discovered devices |
| `error` | `String?` | Nullable | Error message if discovery fails |

**Factory States**:
- `DiscoveryState.initial()` - Not scanning, not broadcasting, empty device list
- `DiscoveryState.scanning()` - Scanning in progress
- `DiscoveryState.error(message)` - Error state with message

---

### LocalDeviceInfo

Information about the current device for broadcasting.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `alias` | `String` | Not Null | Device name (user-configured or hostname) |
| `deviceType` | `DeviceType` | Not Null | Current device category |
| `os` | `String` | Not Null | Operating system name |
| `port` | `int` | Not Null | Port for file transfer service |

**Notes**:
- `alias` sourced from settings repository (fallback: hostname)
- `deviceType` and `os` detected via device_info_plus
- `port` sourced from settings repository (fallback: app default)

---

## Relationships

```
LocalDeviceInfo --broadcasts--> mDNS Service
                                    |
                                    v
mDNS Service <--discovers-- DiscoveryController
                                    |
                                    v
                              DiscoveryState.devices (List<Device>)
```

## State Transitions

### Discovery Lifecycle

```
Initial --> Scanning (startScan)
    |           |
    |           v
    |       Discovered devices added/updated/removed
    |           |
    |           v
    +<----- Stopped (stopScan)
    |
    v
Error (on failure) --> Initial (retry)
```

### Device Lifecycle in List

```
Not in list --> Added (ServiceFound + Resolved)
    |
    v
In list --> Updated (ServiceUpdated, refresh lastSeen)
    |
    v
Removed (ServiceLost OR staleness timeout > 30s)
```

## Validation Rules

1. **Device.ip**: Must be valid IPv4 format
2. **Device.port**: Must be in range 1-65535
3. **Device.alias**: Max 64 characters (mDNS TXT record limit)
4. **DiscoveryState.devices**: No duplicates by unique key

