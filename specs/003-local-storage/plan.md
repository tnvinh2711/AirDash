# Implementation Plan: Local Storage for History and Settings

**Branch**: `003-local-storage` | **Date**: 2025-12-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-local-storage/spec.md`

## Summary

Implement the persistent database layer using Drift (SQLite) for storing user settings (theme, alias, port) and file transfer history. The storage layer will expose repositories accessible via Riverpod providers, supporting real-time streams for history and CRUD operations for settings. Unit tests will use Drift's in-memory database.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM)
**Primary Dependencies**: `drift`, `drift_dev`, `sqlite3_flutter_libs`, `flutter_riverpod`, `riverpod_generator`, `freezed`
**Storage**: Drift (SQLite abstraction) - local database file
**Testing**: `flutter_test` with Drift in-memory database (`NativeDatabase.memory()`)
**Target Platform**: Android, iOS, Windows, macOS, Linux (all platforms via single codebase)
**Project Type**: Mobile/Desktop cross-platform Flutter application
**Performance Goals**: Read/write <100ms, stream updates <500ms, 60fps UI, 10k+ history entries
**Constraints**: Offline-capable (local-only storage), lightweight footprint
**Scale/Scope**: Single-user local storage, ~3 settings keys, unbounded history entries

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Privacy First** | ✅ PASS | All data stored locally; no cloud/server involvement |
| **II. Offline First** | ✅ PASS | SQLite is fully offline; no network required |
| **III. Universal Access** | ✅ PASS | Drift + sqlite3_flutter_libs supports all target platforms |
| **IV. High Performance** | ✅ PASS | SQLite is lightweight; async operations won't block UI |
| **V. Test-First Development** | ✅ PASS | Drift in-memory DB enables fast, isolated unit tests |

| Technology Gate | Status | Notes |
|-----------------|--------|-------|
| State Management: `flutter_riverpod` | ✅ PASS | Using Riverpod providers for repository access |
| Immutability: `freezed` | ✅ PASS | Data models will use Freezed for immutability |
| Local Database: `drift` | ✅ PASS | Required by constitution |
| Architecture: Riverpod Architecture | ✅ PASS | Feature-first with data/application/presentation layers |

| Quality Gate | Requirement | Implementation |
|--------------|-------------|----------------|
| Zero lints | `flutter analyze` passes | Applied to all new code |
| Code formatting | `dart format` applied | Applied to all new code |
| Test coverage | 90% minimum | Unit tests for repositories and providers |
| Platform compat | Mobile + Desktop builds | SQLite supports all platforms |

## Project Structure

### Documentation (this feature)

```text
specs/003-local-storage/
├── plan.md              # This file
├── research.md          # Phase 0: Drift patterns and best practices
├── data-model.md        # Phase 1: Entity definitions and schema
├── quickstart.md        # Phase 1: Developer setup guide
├── contracts/           # Phase 1: Repository interfaces
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── core/
│   │   ├── database/              # NEW: Shared database infrastructure
│   │   │   ├── app_database.dart  # Drift database class
│   │   │   ├── app_database.g.dart # Generated code
│   │   │   └── tables/            # Table definitions
│   │   │       ├── settings_table.dart
│   │   │       └── transfer_history_table.dart
│   │   └── providers/             # NEW: Core providers
│   │       └── database_provider.dart
│   └── features/
│       ├── settings/
│       │   ├── data/              # NEW
│       │   │   └── settings_repository.dart
│       │   ├── application/       # NEW
│       │   │   └── settings_provider.dart
│       │   └── presentation/      # Existing
│       └── history/               # NEW feature folder
│           ├── data/
│           │   └── history_repository.dart
│           ├── application/
│           │   └── history_provider.dart
│           └── domain/
│               └── transfer_history_entry.dart

test/
├── unit/                          # NEW
│   ├── data/
│   │   ├── settings_repository_test.dart
│   │   └── history_repository_test.dart
│   └── application/
│       ├── settings_provider_test.dart
│       └── history_provider_test.dart
└── widget/                        # Existing
```

**Structure Decision**: Following the established Riverpod Architecture (feature-first) pattern. Database infrastructure goes in `core/database/` since it's shared across features. Each feature (settings, history) has its own data and application layers. The `history` feature is new; `settings` extends the existing feature folder.

## Complexity Tracking

> No constitution violations requiring justification. Implementation follows standard patterns.

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion.*

| Gate | Status | Verification |
|------|--------|--------------|
| Privacy First | ✅ PASS | Data model confirms local-only storage; no network fields |
| Offline First | ✅ PASS | SQLite requires no network; all operations local |
| Universal Access | ✅ PASS | `sqlite3_flutter_libs` confirmed for all 5 platforms |
| High Performance | ✅ PASS | Async repository methods; background isolate for DB |
| Test-First | ✅ PASS | In-memory DB pattern documented in quickstart.md |
| State Management | ✅ PASS | Riverpod providers designed in contracts |
| Immutability | ✅ PASS | Drift generates immutable data classes |
| Architecture | ✅ PASS | Feature-first structure with data/application layers |

**Conclusion**: Design artifacts comply with all constitutional requirements. Ready for task breakdown.

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | `research.md` | Drift patterns, best practices, dependency list |
| Data Model | `data-model.md` | Entity definitions, relationships, validation rules |
| Settings Contract | `contracts/settings_repository.dart` | Interface for settings CRUD operations |
| History Contract | `contracts/history_repository.dart` | Interface for history logging and streaming |
| Quickstart | `quickstart.md` | Developer setup guide with code examples |

## Next Steps

Run `/speckit.tasks` to generate the task breakdown for implementation.

