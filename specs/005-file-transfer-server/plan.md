# Implementation Plan: File Transfer Server (Receive Logic)

**Branch**: `005-file-transfer-server` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-file-transfer-server/spec.md`

## Summary

Implement an HTTP server to receive incoming file transfers from peer devices on LAN. The server uses `shelf` and `shelf_router` for HTTP handling, provides two endpoints (`POST /api/v1/info` for handshake, `POST /api/v1/upload` for file streaming), and integrates with existing Discovery (Spec 04) for broadcasting and History (Spec 03) for logging transfers. State is managed via Riverpod with `ServerController` (AsyncNotifier).

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM)
**Primary Dependencies**: `shelf`, `shelf_router` (HTTP server), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models), `archive` (ZIP extraction), `crypto` (checksum)
**Storage**: Drift (via existing `HistoryRepository` for recording transfers), file system (save received files)
**Testing**: `flutter_test` with mocked repository and shelf test utilities
**Target Platform**: Android, iOS, macOS, Windows, Linux (all Flutter desktop/mobile)
**Project Type**: Mobile + Desktop Flutter app (single codebase)
**Performance Goals**: Receive 1GB+ files, server start within 2 seconds, 60fps UI
**Constraints**: Offline-capable (LAN only), single concurrent transfer, 5-minute session timeout
**Scale/Scope**: Typical home/office network transfers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Technology | Required | Planned | Status |
|------------|----------|---------|--------|
| FVM | ✅ | ✅ | PASS |
| flutter_riverpod + riverpod_generator | ✅ | ✅ | PASS |
| freezed | ✅ | ✅ | PASS |
| shelf (HTTP Server receiver) | ✅ | ✅ | PASS |
| bonsoir (discovery) | ✅ | ✅ (Integration via Spec 04) | PASS |
| drift | ✅ | ✅ (Via existing HistoryRepository) | PASS |
| go_router | ✅ | N/A | NOT APPLICABLE (no routing in this feature) |

**Gate Result**: ✅ PASS - All constitution requirements satisfied

## Project Structure

### Documentation (this feature)

```text
specs/005-file-transfer-server/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/src/
├── core/
│   └── providers/
│       └── device_info_provider.dart    # Existing - local device info
└── features/
    ├── discovery/                        # Existing Spec 04 - integrate for broadcast
    │   ├── application/
    │   │   └── discovery_controller.dart # Existing - startBroadcast/stopBroadcast
    │   └── data/
    │       └── discovery_repository.dart # Existing - broadcast operations
    ├── history/                          # Existing Spec 03 - integrate for logging
    │   └── data/
    │       └── history_repository.dart   # Existing - addEntry
    └── receive/
        ├── domain/
        │   ├── transfer_metadata.dart    # NEW - Handshake metadata (Freezed)
        │   ├── transfer_session.dart     # NEW - Active session (Freezed)
        │   └── server_state.dart         # NEW - Server state (Freezed)
        ├── data/
        │   ├── file_server_service.dart  # NEW - shelf HTTP server
        │   └── file_storage_service.dart # NEW - Save files to disk
        ├── application/
        │   └── server_controller.dart    # NEW - AsyncNotifier state management
        └── presentation/
            └── receive_screen.dart       # Existing - update to use ServerController

test/
└── features/
    └── receive/
        ├── application/
        │   └── server_controller_test.dart      # NEW - Unit tests
        └── data/
            ├── file_server_service_test.dart    # NEW - Server endpoint tests
            └── file_storage_service_test.dart   # NEW - Storage tests
```

**Structure Decision**: Follows Riverpod Architecture (Feature-First) as defined in constitution. New `receive` feature layers (domain, data, application) integrate with existing `discovery` and `history` features.

## Complexity Tracking

*No violations - design follows constitution patterns.*

## Phase 0 Output

**Research Document**: [research.md](./research.md)

Key decisions:
- `shelf ^1.4.0` + `shelf_router ^1.1.0` for HTTP server
- `crypto ^3.0.0` for MD5 checksum computation
- `archive ^3.4.0` for ZIP extraction (folder transfers)
- `uuid` for session ID generation
- Streaming file writes via `Request.read()` for memory efficiency
- Session timeout: 5 minutes with timer-based cleanup

## Phase 1 Output

**Data Model**: [data-model.md](./data-model.md)
- TransferMetadata (Freezed) - handshake request payload
- TransferSession (Freezed) - active session with status
- ServerState (Freezed) - root state for controller
- TransferProgress (Freezed) - real-time progress

**Contracts**: `contracts/`
- `api_endpoints.md` - REST API specification
- `server_controller_contract.dart` - Controller/service interfaces

**Quickstart**: [quickstart.md](./quickstart.md)
- Dependency installation commands
- Platform configuration (macOS entitlements)
- Usage examples with Riverpod
- Manual testing with curl

## Constitution Re-Check (Post-Design)

| Technology | Required | Planned | Status |
|------------|----------|---------|--------|
| FVM | ✅ | ✅ | PASS |
| flutter_riverpod + riverpod_generator | ✅ | ✅ | PASS |
| freezed | ✅ | ✅ | PASS |
| shelf (HTTP Server receiver) | ✅ | ✅ | PASS |
| drift | ✅ | ✅ (Via HistoryRepository) | PASS |
| No abstract repository interfaces | ✅ | ✅ | PASS |
| Test-First (90% coverage) | ✅ | ✅ (Unit tests planned) | PASS |

**Post-Design Gate Result**: ✅ PASS - Design complies with constitution
