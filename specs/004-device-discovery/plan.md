# Implementation Plan: Device Discovery Logic

**Branch**: `004-device-discovery` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-device-discovery/spec.md`

## Summary

Implement LAN device discovery and presence broadcasting using mDNS/DNS-SD protocol. The system will enable peer-to-peer device detection for file transfer functionality using the `bonsoir` Flutter package, with a `DiscoveryRepository` for data access and `DiscoveryController` (AsyncNotifier) for state management.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM)
**Primary Dependencies**: `bonsoir` (mDNS), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models)
**Storage**: N/A (in-memory state only; discovered devices are transient)
**Testing**: `flutter_test` with mocked repository for unit tests
**Target Platform**: Android, iOS, macOS, Windows, Linux (all Flutter desktop/mobile)
**Project Type**: Mobile + Desktop Flutter app (single codebase)
**Performance Goals**: Device discovery within 5 seconds, 60fps UI rendering
**Constraints**: Offline-capable (LAN only), no internet required, 30-second staleness timeout
**Scale/Scope**: Typical home/office network (1-50 devices)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy First | ✅ PASS | No external servers; pure LAN mDNS discovery |
| II. Offline First | ✅ PASS | LAN-only operation; no internet required |
| III. Universal Access | ✅ PASS | bonsoir supports Android, iOS, macOS, Windows, Linux |
| IV. High Performance | ✅ PASS | Reactive streams for real-time updates |
| V. Test-First Development | ✅ PASS | Repository mockable for unit testing |

| Technology | Required | Planned | Status |
|------------|----------|---------|--------|
| FVM | ✅ | ✅ | PASS |
| flutter_riverpod + riverpod_generator | ✅ | ✅ | PASS |
| freezed | ✅ | ✅ | PASS |
| bonsoir (discovery) | ✅ | ✅ | PASS |
| go_router | ✅ | N/A | NOT APPLICABLE (no routing in this feature) |
| drift | ✅ | N/A | NOT APPLICABLE (no persistence needed) |

**Gate Result**: ✅ PASS - All constitution requirements satisfied

## Project Structure

### Documentation (this feature)

```text
specs/004-device-discovery/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Dart abstract contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/src/
├── core/
│   └── providers/
│       └── device_info_provider.dart    # Local device info for self-filtering
└── features/
    └── discovery/
        ├── domain/
        │   ├── device.dart              # Device entity (Freezed)
        │   ├── device_type.dart         # DeviceType enum
        │   └── discovery_state.dart     # DiscoveryState (Freezed)
        ├── data/
        │   └── discovery_repository.dart # mDNS operations via bonsoir
        └── application/
            └── discovery_controller.dart # AsyncNotifier state management

test/
└── features/
    └── discovery/
        └── application/
            └── discovery_controller_test.dart # Unit tests with mocked repo
```

**Structure Decision**: Follows Riverpod Architecture (Feature-First) as defined in constitution. Discovery feature contains domain models, data repository, and application controller layers.

## Phase 0 Output

**Research Document**: [research.md](./research.md)

Key decisions:
- `bonsoir ^6.0.1` for mDNS/DNS-SD
- `device_info_plus ^10.1.0` for local device detection
- Service type: `_flux._tcp`
- Self-filtering via service instance name comparison
- 30-second staleness timeout with timestamp tracking

## Phase 1 Output

**Data Model**: [data-model.md](./data-model.md)
- Device entity (7 fields including lastSeen for staleness)
- DeviceType enum (phone, tablet, desktop, laptop, unknown)
- DiscoveryState container (isScanning, isBroadcasting, devices, error)
- LocalDeviceInfo for broadcasting

**Contracts**: `contracts/`
- `discovery_repository_contract.dart` - mDNS operations interface
- `discovery_controller_contract.dart` - State controller interface
- `device_info_provider_contract.dart` - Local device info interface

**Quickstart**: [quickstart.md](./quickstart.md)
- Dependency installation commands
- Platform configuration (iOS Info.plist, macOS entitlements)
- Usage examples with Riverpod

## Constitution Re-Check (Post-Design)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy First | ✅ PASS | No external servers; LAN mDNS only |
| II. Offline First | ✅ PASS | Works without internet |
| III. Universal Access | ✅ PASS | All platforms supported via bonsoir |
| IV. High Performance | ✅ PASS | Stream-based reactive updates |
| V. Test-First Development | ✅ PASS | Repository mockable; controller testable |

| Quality Gate | Status |
|--------------|--------|
| Zero lints expected | ✅ Ready (contracts are pseudocode) |
| Freezed for models | ✅ Planned |
| Riverpod generator | ✅ Planned |
| Platform compatibility | ✅ bonsoir supports all targets |

**Gate Result**: ✅ PASS - Ready for task generation
