# Implementation Plan: Polish and Bug Fixes

**Branch**: `010-polish-and-fixes` | **Date**: 2025-12-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-polish-and-fixes/spec.md`

## Summary

This feature addresses 8 areas: server isolate stability (handshake timeout and stream close errors), accept/decline UI for incoming transfers, transfer progress visibility, completion notifications via toasts, send history recording fix, storage permission handling, device discovery persistence, and port display fix in IdentityCard.

**Technical Approach**:
1. Fix stream lifecycle in `ServerIsolateManager` to prevent "Cannot add events after close" errors
2. Increase handshake timeout and add retry logic for isolate startup
3. Add bottom sheet UI for accept/decline flow with 30-second timeout
4. Add dedicated transfer status bar widget for progress display
5. Implement toast notifications using ScaffoldMessenger
6. Debug and fix send history recording (code exists but may not be triggering)
7. Add `permission_handler` package for Android storage permission
8. Extend device staleness timeout from current setting to 2 minutes
9. Pass actual port from ServerState to IdentityCard instead of using `kDefaultPort`

## Technical Context

**Language/Version**: Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel (FVM)
**Primary Dependencies**: `flutter_riverpod`, `riverpod_generator`, `freezed`, `shelf`, `shelf_router`, `bonsoir`, `drift`, `go_router`, `flex_color_scheme`
**Storage**: Drift (SQLite) for TransferHistory; File system for received files
**Testing**: `flutter_test`, `mocktail` for unit tests
**Target Platform**: Android, iOS, Windows, macOS, Linux
**Project Type**: Cross-platform Flutter mobile/desktop application
**Performance Goals**: 60fps UI, real-time progress updates (at least every second)
**Constraints**: Offline-capable (LAN only), peer-to-peer transfers
**Scale/Scope**: Single user per device, local network discovery

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy First | ✅ PASS | All changes are peer-to-peer, no cloud services |
| Offline First | ✅ PASS | All features work on LAN without Internet |
| Universal Access | ✅ PASS | UI changes use responsive widgets, platform-appropriate patterns |
| High Performance | ✅ PASS | Progress updates throttled, toast notifications are lightweight |
| Test-First Development | ⚠️ WATCH | Need unit tests for new Notifiers and widgets |

| Technology | Status | Notes |
|------------|--------|-------|
| FVM + Flutter Stable | ✅ PASS | Already in use |
| flutter_riverpod + riverpod_generator | ✅ PASS | Already in use |
| freezed | ✅ PASS | Already in use for states |
| drift | ✅ PASS | History already uses Drift |
| go_router | ✅ PASS | Already in use |
| flex_color_scheme | ✅ PASS | Already in use |
| permission_handler | 🆕 NEW | Need to add for Android storage permissions |

## Project Structure

### Documentation (this feature)

```text
specs/010-polish-and-fixes/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (minimal - mostly bug fixes)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/src/
├── core/
│   ├── providers/
│   │   ├── device_info_provider.dart      # Port comes from here (kDefaultPort issue)
│   │   └── permission_provider.dart       # NEW: Storage permission handling
│   └── widgets/
│       ├── transfer_status_bar.dart       # NEW: Dedicated progress bar widget
│       └── toast_helper.dart              # NEW: Toast notification utility
├── features/
│   ├── discovery/
│   │   └── application/
│   │       └── discovery_controller.dart  # Fix staleness timeout (2 min)
│   ├── receive/
│   │   ├── application/
│   │   │   ├── server_controller.dart     # Fix port passing to UI
│   │   │   └── device_identity_provider.dart # Use actual port from ServerState
│   │   ├── data/
│   │   │   └── server_isolate_manager.dart # Fix stream lifecycle and handshake
│   │   └── presentation/
│   │       ├── receive_screen.dart        # Add status bar and toasts
│   │       └── widgets/
│   │           ├── identity_card.dart     # Display actual port
│   │           └── pending_request_sheet.dart # NEW: Accept/Decline bottom sheet
│   └── send/
│       ├── application/
│       │   └── transfer_controller.dart   # Verify history recording works
│       └── presentation/
│           └── send_screen.dart           # Add status bar and toasts

test/
├── features/
│   ├── receive/
│   │   └── application/
│   │       └── server_controller_test.dart # Add tests for new functionality
│   └── discovery/
│       └── application/
│           └── discovery_controller_test.dart # Test staleness timeout
└── core/
    └── widgets/
        └── transfer_status_bar_test.dart  # NEW widget test
```

**Structure Decision**: Follows existing Riverpod Architecture (Feature-First). New widgets go in `core/widgets/` for reuse across features. Permission handling goes in `core/providers/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `permission_handler` package | Android requires runtime permission requests for storage on API 23+ | Without it, file saves silently fail on many Android devices |

No other constitution violations. All changes use existing patterns and approved technologies.
