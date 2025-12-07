# Implementation Plan: Server Background Isolate Refactor

**Branch**: `009-server-background-isolate` | **Date**: 2025-12-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-server-background-isolate/spec.md`

## Summary

Refactor the existing HTTP Server logic to run in a separate Dart Isolate. This solves the OS-level socket creation issue on Android Main Isolate (where `HttpServer.bind()` succeeds but no socket is created) and prevents UI blocking during heavy file transfers. The solution uses Dart's `Isolate.spawn()` with type-safe message passing via SendPort/ReceivePort, wrapped in a ServerIsolateManager that provides a clean API for the UI layer.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM)  
**Primary Dependencies**: `flutter_riverpod`, `riverpod_generator`, `freezed`, `shelf`, `shelf_router`, `archive`, `crypto`  
**Storage**: Drift (SQLite) for history; File system for received files  
**Testing**: `flutter_test` (unit/widget), integration tests via `flutter test integration_test`  
**Target Platform**: Android, iOS, Windows, macOS, Linux (Flutter multi-platform)  
**Project Type**: Mobile/Desktop Flutter application  
**Performance Goals**: 60fps UI, server starts <2s, progress updates <500ms latency, 90%+ network throughput  
**Constraints**: Memory constant during transfer (streaming), max 10 progress updates/sec  
**Scale/Scope**: Single active transfer session, files up to 10GB

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy First | ✅ PASS | Isolate runs locally, no external servers |
| Offline First | ✅ PASS | LAN-only, no internet required |
| Universal Access | ✅ PASS | Isolate API works on all platforms |
| High Performance | ✅ PASS | Isolate prevents UI blocking |
| Test-First Development | ⚠️ TBD | Tests to be written for isolate manager |
| Technology Stack | ✅ PASS | Uses mandated stack (Riverpod, Freezed, Shelf) |
| Architecture | ✅ PASS | Feature-first, Application layer notifiers |

**Gate Result**: ✅ PASS - No violations, proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/009-server-background-isolate/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (IsolateCommand/Event definitions)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/src/features/receive/
├── data/
│   ├── file_server_service.dart       # MODIFY: Remove isolate prototype, delegate to manager
│   ├── file_storage_service.dart      # EXISTING: No changes needed
│   └── server_isolate_manager.dart    # NEW: Manages isolate lifecycle
├── application/
│   ├── server_controller.dart         # MODIFY: Use new isolate manager
│   └── receive_settings_provider.dart # EXISTING: No changes needed
├── domain/
│   ├── isolate_command.dart           # NEW: Commands to isolate (Freezed union)
│   ├── isolate_event.dart             # NEW: Events from isolate (Freezed union)
│   ├── isolate_config.dart            # NEW: Startup config (settings snapshot)
│   ├── transfer_session.dart          # MODIFY: Add state transitions
│   ├── session_status.dart            # MODIFY: Rename states per clarification
│   └── ... (existing files unchanged)
└── presentation/
    └── ... (no changes in this feature)

test/features/receive/
├── data/
│   └── server_isolate_manager_test.dart  # NEW: Unit tests for manager
├── application/
│   └── server_controller_test.dart       # MODIFY: Test with mock manager
└── domain/
    ├── isolate_command_test.dart         # NEW: Serialization tests
    └── isolate_event_test.dart           # NEW: Serialization tests
```

**Structure Decision**: Riverpod Architecture (Feature-First) - New isolate management code in `data/` layer (infrastructure), domain models in `domain/`, existing `application/` layer coordinates.

## Complexity Tracking

No constitution violations. No complexity justifications needed.

