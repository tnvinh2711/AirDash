# Implementation Plan: File Transfer Client (Send Logic)

**Branch**: `006-file-transfer-client` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-file-transfer-client/spec.md`

## Summary

Implement client-side logic to select content (files, folders, text) and send it to a receiver device on LAN. Uses `dio` for HTTP requests, `file_picker` for file/folder selection, and `archive` for ZIP compression. Two controllers manage state: `FileSelectionController` (selection queue) and `TransferController` (handshake → upload flow). Integrates with existing Discovery (Spec 04) for target device selection and History (Spec 03) for logging sent transfers. Sequential transfer of multiple items with partial failure handling.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM)
**Primary Dependencies**: `dio` (HTTP client), `file_picker` (file/folder selection), `archive` (ZIP compression), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models), `crypto` (checksum)
**Storage**: Drift (via existing `HistoryRepository` for recording transfers)
**Testing**: `flutter_test` with mocked services; unit tests for compression, transfer logic
**Target Platform**: Android, iOS, macOS, Windows, Linux (all Flutter desktop/mobile)
**Project Type**: Mobile + Desktop Flutter app (single codebase)
**Performance Goals**: Send 1GB+ files, file picker within 1s, folder compression <30s for 500MB, 60fps UI
**Constraints**: LAN-only (no Internet required), offline-capable, must handle cancellation gracefully
**Scale/Scope**: P2P transfer to single receiver, multi-item selection queue, sequential transfers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status | Notes |
|------|-------------|--------|-------|
| SDK Management | FVM required | ✅ PASS | Project uses FVM |
| State Management | flutter_riverpod + riverpod_generator | ✅ PASS | Using @riverpod annotation pattern |
| Immutability | freezed for data classes | ✅ PASS | All domain models use freezed |
| HTTP Client | Constitution says `chopper` for sender | ⚠️ DEVIATION | User spec requests `dio` - see Complexity Tracking |
| Storage | drift for history | ✅ PASS | Existing HistoryRepository integration |
| Architecture | Riverpod Architecture (Feature-First) | ✅ PASS | Following existing pattern |
| No Use Cases | Logic in Application Layer | ✅ PASS | Controllers handle logic directly |
| Test Coverage | 90% target | ✅ PASS | Unit tests planned for data/application layers |

## Project Structure

### Documentation (this feature)

```text
specs/006-file-transfer-client/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/src/features/send/
├── domain/              # Data models (SelectedItem, TransferPayload, TransferState)
│   ├── selected_item.dart
│   ├── selected_item_type.dart
│   ├── transfer_payload.dart
│   ├── transfer_state.dart
│   └── transfer_result.dart
├── data/                # Services (file picker, compression, HTTP client)
│   ├── file_picker_service.dart
│   ├── compression_service.dart
│   └── transfer_client_service.dart
├── application/         # Controllers (FileSelectionController, TransferController)
│   ├── file_selection_controller.dart
│   └── transfer_controller.dart
└── presentation/        # (Existing) UI screens - minimal changes
    └── send_screen.dart

test/features/send/
├── data/
│   ├── file_picker_service_test.dart
│   ├── compression_service_test.dart
│   └── transfer_client_service_test.dart
└── application/
    ├── file_selection_controller_test.dart
    └── transfer_controller_test.dart
```

**Structure Decision**: Follows Riverpod Architecture (Feature-First) as defined in constitution. New `send` feature layers (domain, data, application) integrate with existing `discovery` (Device model) and `history` (HistoryRepository) features. Presentation layer already exists with placeholder screen.

## Complexity Tracking

> **Justification for Constitution Deviation**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `dio` instead of `chopper` | User explicitly requested `dio` in spec; `dio` has simpler API for streaming uploads with progress callbacks | `chopper` requires code generation and more boilerplate for simple REST calls; `dio` is more common in Flutter community for file uploads |

**Note**: Both `dio` and `chopper` are mature HTTP clients. Constitution preference for `chopper` is advisory for consistency, but `dio` is functionally equivalent and better suited for streaming upload progress tracking.

## Phase 0 Output

**Research Document**: [research.md](./research.md)

Key decisions:
- `dio ^5.0.0` for HTTP client with streaming upload and progress callbacks
- `file_picker ^8.0.0` for cross-platform file/folder selection
- `archive ^3.4.0` for ZIP compression (same as receiver)
- `crypto ^3.0.0` for MD5 checksum (same as receiver)
- Sequential transfer model for multi-item selection
- Cancellation via CancelToken (dio)

## Phase 1 Output

- **Data Model**: [data-model.md](./data-model.md)
- **Contracts**: [contracts/](./contracts/) (client-side DTOs for existing server API)
- **Quickstart**: [quickstart.md](./quickstart.md)

## Constitution Re-Check (Post-Design)

| Gate | Status | Notes |
|------|--------|-------|
| Privacy First | ✅ PASS | No cloud services; P2P only |
| Offline First | ✅ PASS | LAN-only, no Internet required |
| Universal Access | ✅ PASS | file_picker supports all platforms |
| High Performance | ✅ PASS | Streaming uploads, 60fps UI |
| Test-First | ✅ PASS | Unit tests for all layers planned |
| Riverpod Architecture | ✅ PASS | Feature-first structure maintained |
| freezed for models | ✅ PASS | All domain models use freezed |
| No Use Cases | ✅ PASS | Logic in Controllers/Services only |

**Conclusion**: Design passes all constitution gates. One justified deviation (dio vs chopper) documented in Complexity Tracking.
