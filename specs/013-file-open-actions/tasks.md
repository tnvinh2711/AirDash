# Tasks: File Open Actions

**Input**: Design documents from `/specs/013-file-open-actions/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Tests are NOT explicitly requested in the specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All paths relative to repository root

---

## Phase 1: Setup

**Purpose**: Add dependency and prepare project for feature implementation

- [x] T001 Add `open_filex` package via `flutter pub add open_filex`
- [x] T002 [P] Create FileOpenResult enum in `lib/src/core/providers/file_open_result.dart`
- [x] T003 [P] Create FileOpenService in `lib/src/core/providers/file_open_service.dart`
- [x] T004 Create FileOpenService Riverpod provider in `lib/src/core/providers/file_open_service_provider.dart`

---

## Phase 2: Foundational (Database Migration)

**Purpose**: Update database schema - MUST complete before ANY user story can use savedPath

**⚠️ CRITICAL**: No user story work can begin until database migration is complete

- [x] T005 Add `savedPath` column to `lib/src/core/database/tables/transfer_history_table.dart`
- [x] T006 Update schema version to 2 and add migration in `lib/src/core/database/app_database.dart`
- [x] T007 Add `savedPath` field to `lib/src/features/history/domain/transfer_history_entry.dart`
- [x] T008 [P] Add `savedPath` field to `lib/src/features/history/domain/new_transfer_history_entry.dart`
- [x] T009 Update `_mapToEntry` method in `lib/src/features/history/data/history_repository.dart`
- [x] T010 Update `addEntry` method in `lib/src/features/history/data/history_repository.dart`
- [x] T011 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate database code

**Checkpoint**: Database ready with savedPath column - user story implementation can now begin

---

## Phase 3: User Story 1 - Open File from Transfer History (Priority: P1) 🎯 MVP

**Goal**: Users can tap on completed received transfers in history to open files

**Independent Test**: Receive a file → Open transfer history → Tap entry → Verify file opens in default app

### Implementation for User Story 1

- [x] T012 [US1] Update server to pass savedPath when recording history in `lib/src/features/receive/application/server_controller.dart`
- [x] T013 [US1] Add `canOpenFile` getter to TransferHistoryEntry in `lib/src/features/history/domain/transfer_history_entry.dart`
- [x] T014 [US1] Add tap handler to HistoryListItem in `lib/src/features/receive/presentation/widgets/history_list_item.dart`
- [x] T015 [US1] Implement file open action in tap handler using FileOpenService
- [x] T016 [US1] Add visual indicator for tappable entries (received with savedPath) in history list item
- [x] T017 [US1] Handle "File not found" error with snackbar message
- [x] T018 [US1] Handle "Path not available" for legacy entries (null savedPath)
- [x] T019 [US1] Handle sent transfers (show details only, no open action)

**Checkpoint**: User Story 1 complete - users can tap history entries to open received files

---

## Phase 4: User Story 2 - Post-Transfer Completion Popup (Priority: P1) 🎯 MVP

**Goal**: Popup appears after successful file receipt with Open/Show actions

**Independent Test**: Receive a file → Verify popup appears → Tap "Open File" → Verify file opens

### Implementation for User Story 2

- [x] T020 [US2] Create TransferCompleteDialog widget in `lib/src/features/receive/presentation/widgets/transfer_complete_dialog.dart`
- [x] T021 [US2] Implement "Open File" button action using FileOpenService
- [x] T022 [US2] Implement "Show in Folder" button action using FileOpenService
- [x] T023 [US2] Implement dismiss button action
- [x] T024 [US2] Handle folder transfers (show "Open Folder" instead of "Open File")
- [x] T025 [US2] Add showTransferCompleteDialog helper function
- [x] T026 [US2] Integrate popup trigger in receive completion flow in `lib/src/features/receive/presentation/receive_screen.dart`
- [x] T027 [US2] Ensure popup only shows for successful transfers (not failed/cancelled)
- [x] T028 [US2] Support multiple popups stacking for concurrent transfers

**Checkpoint**: User Story 2 complete - completion popup shows after successful transfers

---

## Phase 5: User Story 3 - Show in Folder Option (Priority: P2)

**Goal**: Context menu option to reveal received file in file manager

**Independent Test**: View history → Long-press entry → Select "Show in Folder" → Verify file browser opens

### Implementation for User Story 3

- [x] T029 [US3] Add long-press handler to HistoryListItem in `lib/src/features/receive/presentation/widgets/history_list_item.dart`
- [x] T030 [US3] Create context menu with "Open File" and "Show in Folder" options
- [x] T031 [US3] Implement "Show in Folder" action using FileOpenService.showInFolder
- [x] T032 [US3] Handle folder not found error with appropriate message
- [x] T033 [US3] Disable context menu for sent transfers and legacy entries

**Checkpoint**: User Story 3 complete - users can reveal files in file manager

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, edge cases, and code quality

- [x] T034 Handle permission denied errors across all platforms
- [x] T035 Handle "no app available" errors with user-friendly message
- [x] T036 Add logging for file open operations
- [x] T037 Run `dart format .` to ensure code formatting
- [x] T038 Run `dart analyze` to verify zero lints
- [ ] T039 Verify migration works correctly (fresh install + upgrade from v1)
- [ ] T040 Test on macOS and Android minimum

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on T001 (package installed) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion
- **User Story 2 (Phase 4)**: Depends on Phase 2 completion (can parallel with US1)
- **User Story 3 (Phase 5)**: Depends on Phase 2 completion (can parallel with US1, US2)
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent - can start after Phase 2
- **User Story 2 (P1)**: Independent - can start after Phase 2, parallelize with US1
- **User Story 3 (P2)**: Independent - can start after Phase 2, lower priority

### Parallel Opportunities

**Phase 1**:
- T002, T003 can run in parallel (different files)

**Phase 2**:
- T007, T008 can run in parallel (different domain files)

**User Stories (after Phase 2)**:
- US1, US2, US3 can all start in parallel (different UI components)

---

## Parallel Example: Phase 1 Setup

```bash
# Launch in parallel:
Task T002: "Create FileOpenResult enum in lib/src/core/services/file_open_result.dart"
Task T003: "Create FileOpenService in lib/src/core/services/file_open_service.dart"
```

## Parallel Example: User Stories

```bash
# After Phase 2, launch US1 and US2 in parallel:
US1 starts at T012: "Update server to pass savedPath when recording history"
US2 starts at T020: "Create TransferCompleteDialog widget"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T011) - **CRITICAL BLOCKER**
3. Complete Phase 3: User Story 1 (T012-T019)
4. Complete Phase 4: User Story 2 (T020-T028)
5. **STOP and VALIDATE**: Test both MVP stories
6. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Database ready
2. Add User Story 1 → Test tapping history to open files → MVP increment 1
3. Add User Story 2 → Test completion popup → MVP increment 2
4. Add User Story 3 → Test show in folder → Full feature
5. Polish → Production ready

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story
- US1 and US2 are both P1 priority (MVP scope)
- US3 is P2 priority (can be deferred)
- Commit after each logical group of tasks
- Test savedPath migration before proceeding to user stories

