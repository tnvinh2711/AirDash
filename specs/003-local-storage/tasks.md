# Tasks: Local Storage for History and Settings

**Input**: Design documents from `/specs/003-local-storage/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: Not requested in spec. Test tasks omitted (add via TDD approach if needed).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Paths use Flutter structure: `lib/src/`, `test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency management

- [x] T001 Add Drift dependencies: `flutter pub add drift sqlite3_flutter_libs path_provider path`
- [x] T002 Add Drift dev dependency: `flutter pub add --dev drift_dev`
- [x] T003 [P] Create database directory structure: `lib/src/core/database/tables/`
- [x] T004 [P] Create history feature directory structure: `lib/src/features/history/data/`, `lib/src/features/history/application/`, `lib/src/features/history/domain/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core database infrastructure - MUST complete before ANY user story

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Create TransferStatus enum in `lib/src/features/history/domain/transfer_status.dart`
- [x] T006 [P] Create TransferDirection enum in `lib/src/features/history/domain/transfer_direction.dart`
- [x] T007 [P] Create SettingsTable definition in `lib/src/core/database/tables/settings_table.dart`
- [x] T008 [P] Create TransferHistoryTable definition with enum converters in `lib/src/core/database/tables/transfer_history_table.dart`
- [x] T009 Create AppDatabase class importing both tables in `lib/src/core/database/app_database.dart`
- [x] T010 Create database connection helper in `lib/src/core/database/connection/connection.dart`
- [x] T011 Create database provider (keepAlive: true) in `lib/src/core/providers/database_provider.dart`
- [x] T012 Run code generation: `dart run build_runner build --delete-conflicting-outputs`
- [x] T013 Verify generated files exist: `app_database.g.dart`, `database_provider.g.dart`

**Checkpoint**: Database foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Persistent User Settings (Priority: P1) 🎯 MVP

**Goal**: User preferences (theme, alias, port) persist across app restarts

**Independent Test**: Change a setting, close app, reopen, verify setting persists

### Implementation for User Story 1

- [x] T014 [US1] Create SettingsRepository implementing ISettingsRepository in `lib/src/features/settings/data/settings_repository.dart`
- [x] T015 [US1] Implement getSetting/setSetting generic methods in SettingsRepository
- [x] T016 [US1] Implement getTheme/setTheme methods in SettingsRepository
- [x] T017 [US1] Implement getAlias/setAlias methods in SettingsRepository
- [x] T018 [US1] Implement getPort/setPort methods with int conversion in SettingsRepository

**Checkpoint**: User Story 1 complete - settings persist across app restarts

---

## Phase 4: User Story 2 - Transfer History Logging (Priority: P1)

**Goal**: File transfers are recorded in history with all details (status, direction, device)

**Independent Test**: Complete a transfer, verify history record appears with correct details

### Implementation for User Story 2

- [x] T019 [US2] Create NewTransferHistoryEntry DTO in `lib/src/features/history/domain/new_transfer_history_entry.dart`
- [x] T020 [US2] Create TransferHistoryEntry domain model in `lib/src/features/history/domain/transfer_history_entry.dart`
- [x] T021 [US2] Create HistoryRepository class in `lib/src/features/history/data/history_repository.dart`
- [x] T022 [US2] Implement addEntry method with auto-timestamp in HistoryRepository
- [x] T023 [US2] Add companion insert logic using Drift's Companion pattern

**Checkpoint**: User Story 2 complete - transfers can be logged to history

---

## Phase 5: User Story 3 - View Transfer History (Priority: P2)

**Goal**: Transfer history displays as live-updating stream (no manual refresh)

**Independent Test**: View history list, complete a transfer, verify new entry appears automatically

### Implementation for User Story 3

- [x] T024 [US3] Implement watchAllEntries stream method in HistoryRepository in `lib/src/features/history/data/history_repository.dart`
- [x] T025 [US3] Implement getAllEntries one-time read method in HistoryRepository
- [x] T026 [US3] Implement getEntryById lookup method in HistoryRepository
- [x] T027 [US3] Add timestamp ordering (newest first) to all query methods

**Checkpoint**: User Story 3 complete - history updates appear in real-time

---

## Phase 6: User Story 4 - Settings Access via Provider (Priority: P2)

**Goal**: Clean Riverpod provider integration for settings and history across UI components

**Independent Test**: Use provider to read/write setting, verify data flows correctly

### Implementation for User Story 4

- [x] T028 [US4] Create SettingsRepositoryProvider in `lib/src/features/settings/application/settings_provider.dart`
- [x] T029 [US4] Create convenience providers for theme/alias/port in `lib/src/features/settings/application/settings_provider.dart`
- [x] T030 [US4] Create HistoryRepositoryProvider in `lib/src/features/history/application/history_provider.dart`
- [x] T031 [US4] Create historyStreamProvider using StreamProvider in `lib/src/features/history/application/history_provider.dart`
- [x] T032 [US4] Run final code generation: `dart run build_runner build --delete-conflicting-outputs`

**Checkpoint**: User Story 4 complete - all storage accessible via providers

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation and cleanup

- [x] T033 Verify `flutter analyze` passes with zero lints
- [x] T034 [P] Run `dart format lib/src/core/database/` and `lib/src/features/`
- [x] T035 [P] Validate quickstart.md examples work correctly
- [ ] T036 Manual test: Set theme, close app, reopen, verify theme persists
- [ ] T037 Manual test: Add history entry, verify it appears in stream

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - can start after T013
- **User Story 2 (Phase 4)**: Depends on Foundational - can run parallel to US1
- **User Story 3 (Phase 5)**: Depends on US2 (shares HistoryRepository)
- **User Story 4 (Phase 6)**: Depends on US1 + US3 (wraps both repositories)
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

```
Setup (Phase 1)
    │
    ▼
Foundational (Phase 2) ─── BLOCKS ALL ───
    │                                    │
    ├──────────────┬─────────────────────┤
    ▼              ▼                     │
  US1 (P1)      US2 (P1)                 │
    │              │                     │
    │              ▼                     │
    │           US3 (P2)                 │
    │              │                     │
    └──────┬───────┘                     │
           ▼                             │
        US4 (P2)                         │
           │                             │
           ▼                             │
        Polish                           │
```

### Parallel Opportunities

**Phase 1 (Setup)**:
- T003 + T004: Create directory structures in parallel

**Phase 2 (Foundational)**:
- T005 + T006 + T007 + T008: All table/enum definitions in parallel

**After Foundational**:
- US1 + US2 can proceed in parallel (different features, different files)

---

## Parallel Example: Foundational Phase

```bash
# Launch all table/enum definitions together:
Task: "Create TransferStatus enum in lib/src/features/history/domain/transfer_status.dart"
Task: "Create TransferDirection enum in lib/src/features/history/domain/transfer_direction.dart"
Task: "Create SettingsTable definition in lib/src/core/database/tables/settings_table.dart"
Task: "Create TransferHistoryTable definition in lib/src/core/database/tables/transfer_history_table.dart"
```

## Parallel Example: User Stories 1 & 2

```bash
# After Foundational completes, launch both P1 stories:
Developer A: User Story 1 (T014-T018) - Settings Repository
Developer B: User Story 2 (T019-T023) - History Repository
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T013)
3. Complete Phase 3: User Story 1 (T014-T018)
4. **STOP and VALIDATE**: Test settings persistence independently
5. Deploy/demo if ready - users can save preferences!

### Incremental Delivery

1. **MVP**: Setup + Foundational + US1 → Settings persist ✓
2. **+Logging**: Add US2 → Transfer history recorded ✓
3. **+Live Updates**: Add US3 → History streams in real-time ✓
4. **+Provider Layer**: Add US4 → Clean state management ✓
5. **Polish**: Final validation and cleanup

### Single Developer Flow

```
T001 → T002 → T003,T004 → T005,T006,T007,T008 → T009 → T010 → T011 → T012 → T013
                                                                              ↓
T014 → T015 → T016 → T017 → T018 (US1 COMPLETE - MVP!)
                              ↓
T019 → T020 → T021 → T022 → T023 (US2 COMPLETE)
                              ↓
T024 → T025 → T026 → T027 (US3 COMPLETE)
                       ↓
T028 → T029 → T030 → T031 → T032 (US4 COMPLETE)
                              ↓
T033 → T034 → T035 → T036 → T037 (POLISH COMPLETE)
```

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story should be independently testable after completion
- Run `dart run build_runner build` after creating tables (T012) and after providers (T032)
- Commit after each phase or logical group
- Stop at any checkpoint to validate story independently

