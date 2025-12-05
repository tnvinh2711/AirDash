# Implementation Plan: Project Initialization with FVM and Folder Structure

**Branch**: `001-project-init` | **Date**: 2025-12-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-project-init/spec.md`

## Summary

Initialize a Flutter project using FVM with the `stable` channel, install constitution-mandated dependencies (flutter_riverpod, freezed, go_router, flex_color_scheme), create the Riverpod Architecture folder structure, and configure Very Good Analysis linting. The project must build and run on all 5 target platforms (Android, iOS, macOS, Windows, Linux).

## Technical Context

**Language/Version**: Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel
**Primary Dependencies**:
- Runtime: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `flex_color_scheme`, `freezed_annotation`
- Dev: `riverpod_generator`, `freezed`, `build_runner`, `very_good_analysis`
**Storage**: N/A (initialization only - drift to be added in future features)
**Testing**: `flutter_test` (built-in), targeting 90% coverage per constitution
**Target Platform**: Android, iOS, macOS, Windows, Linux (all 5 platforms)
**Project Type**: Flutter mobile + desktop (single codebase, multi-platform)
**Performance Goals**: 60fps+ UI rendering (constitution requirement)
**Constraints**: Offline-capable, no cloud dependencies (constitution principles I & II)
**Scale/Scope**: Initial project scaffold - foundation for FLUX file-sharing app

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy First | ✅ PASS | No external services in init |
| II. Offline First | ✅ PASS | No network dependencies in scaffold |
| III. Universal Access | ✅ PASS | All 5 platforms targeted |
| IV. High Performance | ✅ PASS | Default Flutter app meets 60fps |
| V. Test-First Development | ⚠️ DEFERRED | 90% coverage applies to future features, not scaffold |

| Technology Stack | Status | Notes |
|------------------|--------|-------|
| FVM | ✅ REQUIRED | Using `stable` channel per clarification |
| flutter_riverpod + riverpod_generator | ✅ INCLUDED | Per FR-004 |
| freezed + freezed_annotation | ✅ INCLUDED | Per FR-004, FR-005 |
| go_router | ✅ INCLUDED | Per FR-004 |
| flex_color_scheme | ✅ INCLUDED | Per FR-004 |
| very_good_analysis | ✅ INCLUDED | Per FR-007 |

| Quality Gate | Status | Notes |
|--------------|--------|-------|
| Zero lints | ✅ REQUIRED | FR-008: `flutter analyze` must pass |
| Code formatting | ✅ REQUIRED | `dart format` applied |
| Platform compatibility | ✅ REQUIRED | All 5 platforms per SC-004 |

**GATE RESULT**: ✅ PASS - All constitution requirements satisfied or appropriately deferred.

## Project Structure

### Documentation (this feature)

```text
specs/001-project-init/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── core/               # Shared logic, common widgets, extensions
│   └── features/           # Feature modules (empty for now)
├── app.dart                # Root widget placeholder
└── main.dart               # Entry point

test/
└── widget_test.dart        # Default Flutter test (placeholder)

.fvm/
├── fvm_config.json         # FVM configuration (stable channel)
└── flutter_sdk             # Symlink to Flutter SDK (gitignored)

analysis_options.yaml       # Very Good Analysis configuration
pubspec.yaml                # Dependencies per FR-004, FR-005
```

**Structure Decision**: Flutter mobile + desktop structure per constitution's Riverpod Architecture. The `lib/src/features/` directory is empty initially - features will add their own `data/`, `application/`, `presentation/`, `domain/` subdirectories as needed.

## Complexity Tracking

> No violations - this feature follows constitution requirements exactly.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | N/A | N/A |
