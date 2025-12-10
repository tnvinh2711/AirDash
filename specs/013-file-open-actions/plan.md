# Implementation Plan: File Open Actions

**Branch**: `013-file-open-actions` | **Date**: 2025-12-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-file-open-actions/spec.md`

## Summary

Add file opening capabilities to transfer history entries and a completion popup after successful file receipt. Users can tap on received files in history to open them, or use "Show in Folder" to navigate to the file location. When a transfer completes, a popup offers immediate access to open the file or show its location.

**Key Technical Changes**:
1. Add `savedPath` column to transfer history database table (Drift migration)
2. Add `open_file` package for cross-platform file opening
3. Implement completion popup dialog with Open/Show actions
4. Make history list items tappable for received transfers

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM)
**Primary Dependencies**: `flutter_riverpod`, `riverpod_generator`, `freezed`, `drift`, `go_router`, `flex_color_scheme`, `open_filex` (NEW)
**Storage**: Drift (SQLite) - existing `TransferHistoryTable`, requires migration to add `savedPath` column
**Testing**: `flutter_test`, `mocktail`, targeting 90% coverage per constitution
**Target Platform**: Android, iOS, macOS, Windows, Linux (all 5 platforms)
**Project Type**: Flutter mobile + desktop (single codebase, multi-platform)
**Performance Goals**: 60fps+ UI rendering, file open action <2 seconds
**Constraints**: Offline-capable, no cloud dependencies, platform-native file opening
**Scale/Scope**: 2 new UI components (popup dialog, enhanced history item), 1 DB migration, 1 new service

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy First | ✅ PASS | No external services; all file operations are local |
| II. Offline First | ✅ PASS | File opening uses platform-native APIs, no network required |
| III. Universal Access | ✅ PASS | Cross-platform file opening via `open_file` package |
| IV. High Performance | ✅ PASS | File opening is async, won't block UI |
| V. Test-First Development | ✅ PASS | Unit tests for service/repository, widget tests for popup |

| Quality Gate | Status | Notes |
|--------------|--------|-------|
| Zero lints | ⏳ TBD | Will verify after implementation |
| Code formatting | ⏳ TBD | Will apply `dart format` |
| Test coverage | ⏳ TBD | Target 90% for new code |
| Platform compatibility | ⏳ TBD | Will test on macOS + Android minimum |

| Technology | Constitutional? | Notes |
|------------|-----------------|-------|
| `open_filex` | ⚠️ NEW | Not in constitution; needs justification |

**Justification for `open_filex`**: Constitution does not specify a file opening package. This capability is required for the feature. `open_filex` is a well-maintained fork of `open_file` with 413 likes and 351k downloads, supporting all 5 target platforms (Android, iOS, macOS, Windows, Linux). Alternative: `url_launcher` (more limited, primarily for URLs, inconsistent file:// support).

## Project Structure

### Documentation (this feature)

```text
specs/013-file-open-actions/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/src/
├── core/
│   ├── database/
│   │   ├── app_database.dart         # Update: add migration for savedPath
│   │   └── tables/
│   │       └── transfer_history_table.dart  # Update: add savedPath column
│   └── services/
│       └── file_open_service.dart    # NEW: cross-platform file opening
│
├── features/
│   ├── history/
│   │   ├── domain/
│   │   │   ├── transfer_history_entry.dart  # Update: add savedPath field
│   │   │   └── new_transfer_history_entry.dart  # Update: add savedPath field
│   │   └── data/
│   │       └── history_repository.dart  # Update: include savedPath in queries
│   │
│   └── receive/
│       ├── application/
│       │   └── server_controller.dart  # Update: pass savedPath to history
│       └── presentation/
│           └── widgets/
│               ├── history_list_item.dart  # Update: add tap handler
│               └── transfer_complete_dialog.dart  # NEW: completion popup

test/
├── core/
│   └── services/
│       └── file_open_service_test.dart  # NEW
└── features/
    └── receive/
        └── presentation/
            └── widgets/
                └── transfer_complete_dialog_test.dart  # NEW
```

**Structure Decision**: Flutter single-codebase multi-platform app following Riverpod Architecture (Pragmatic, Feature-First) as defined in constitution.

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
|----------|------------|-------------------------------------|
| `open_filex` package | Required for opening files with platform default apps | No built-in Flutter API for this; `url_launcher` doesn't support file:// on all platforms |
