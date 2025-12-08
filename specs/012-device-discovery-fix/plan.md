# Implementation Plan: Device Discovery Bug Fixes

**Branch**: `012-device-discovery-fix` | **Date**: 2024-12-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-device-discovery-fix/spec.md`

## Summary

Fix two bugs in device discovery for the Send screen:
1. **Refresh button always loading**: Add scan timeout timer (5 seconds) to automatically stop scanning
2. **Devices disappear quickly**: Add grace period (30 seconds) before removing devices on `DeviceLostEvent`

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM)
**Primary Dependencies**: `flutter_riverpod`, `riverpod_generator`, `bonsoir` (mDNS)
**Storage**: N/A (in-memory state only for discovery)
**Testing**: `flutter test` with existing discovery controller tests
**Target Platform**: Android, iOS, macOS, Windows, Linux
**Project Type**: Flutter mobile/desktop application
**Performance Goals**: 60fps UI, scan timeout ≤10 seconds
**Constraints**: LAN-only, offline-capable, no external services
**Scale/Scope**: Bug fix - 1 controller file, ~50 lines of changes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| **Privacy First** | ✅ PASS | No data leaves device; LAN-only discovery |
| **Offline First** | ✅ PASS | mDNS works without internet |
| **Universal Access** | ✅ PASS | Fix applies to all platforms equally |
| **High Performance** | ✅ PASS | Scan timeout improves UX responsiveness |
| **Test-First Development** | ✅ PASS | Existing tests to be updated |
| **Technology Stack** | ✅ PASS | Uses mandated `flutter_riverpod`, `bonsoir` |
| **Architecture** | ✅ PASS | Changes in Application layer (Notifier) only |

## Project Structure

### Documentation (this feature)

```text
specs/012-device-discovery-fix/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Already created
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
lib/src/features/discovery/
├── application/
│   └── discovery_controller.dart    # PRIMARY: Add timeout + grace period
├── data/
│   └── discovery_repository.dart    # No changes needed
└── domain/
    ├── device.dart                  # No changes needed
    └── discovery_state.dart         # Possibly add pendingLost tracking

test/features/discovery/
└── application/
    └── discovery_controller_test.dart  # Update tests
```

**Structure Decision**: Flutter feature-first architecture. All changes confined to the `discovery` feature's application layer.

## Complexity Tracking

> No constitution violations. Bug fix with minimal scope.

| Aspect | Complexity | Notes |
|--------|------------|-------|
| Files Changed | 1-2 | `discovery_controller.dart`, possibly `discovery_state.dart` |
| New Dependencies | 0 | Uses existing `dart:async` Timer |
| New Patterns | 0 | Standard timer-based timeout pattern |
| Test Changes | 1 | Update existing controller tests |
