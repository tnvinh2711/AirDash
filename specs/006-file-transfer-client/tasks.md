# Tasks: File Transfer Client (Send Logic)

**Input**: Design documents from `/specs/006-file-transfer-client/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Included (explicitly requested in spec.md: "Unit test for folder selection creating valid zip file")

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story mapping (US1, US2, US3, US4)
- Exact file paths included

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies and project structure initialization

- [x] T001 Add `dio: ^5.0.0` and `file_picker: ^8.0.0` dependencies to pubspec.yaml
- [x] T002 Create directory structure: `lib/src/features/send/domain/`, `lib/src/features/send/data/`, `lib/src/features/send/application/`
- [x] T003 Create test directory structure: `test/features/send/data/`, `test/features/send/application/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models and DTOs that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Create `SelectedItemType` enum in `lib/src/features/send/domain/selected_item_type.dart`
- [x] T005 [P] Create `SelectedItem` freezed model in `lib/src/features/send/domain/selected_item.dart`
- [x] T006 [P] Create `TransferPayload` freezed model in `lib/src/features/send/domain/transfer_payload.dart`
- [x] T007 [P] Create `TransferResult` freezed model in `lib/src/features/send/domain/transfer_result.dart`
- [x] T008 [P] Create `TransferPhase` enum in `lib/src/features/send/domain/transfer_phase.dart`
- [x] T009 [P] Create `TransferProgress` freezed model in `lib/src/features/send/domain/transfer_progress.dart`
- [x] T010 Create `TransferState` freezed union in `lib/src/features/send/domain/transfer_state.dart`
- [x] T011 [P] Create `HandshakeRequest` freezed DTO in `lib/src/features/send/data/dtos/handshake_request.dart`
- [x] T012 [P] Create `HandshakeResponse` freezed DTO in `lib/src/features/send/data/dtos/handshake_response.dart`
- [x] T013 [P] Create `UploadResponse` freezed DTO in `lib/src/features/send/data/dtos/upload_response.dart`
- [x] T014 Run `fvm dart run build_runner build --delete-conflicting-outputs` to generate freezed code

**Checkpoint**: Foundation ready - domain models available, user story implementation can begin

---

## Phase 3: User Story 1 - Send Single File (Priority: P1) 🎯 MVP

**Goal**: Select a file and send it to another device on LAN with progress tracking

**Independent Test**: Select file → choose receiver → initiate send → verify file received with checksum

### Tests for User Story 1

- [x] T015 [P] [US1] Create unit test for `CompressionService.computeChecksum` in `test/features/send/data/compression_service_test.dart`
- [x] T016 [P] [US1] Create unit test for `TransferClientService.handshake` in `test/features/send/data/transfer_client_service_test.dart`
- [x] T017 [P] [US1] Create unit test for `TransferClientService.upload` with progress callback in `test/features/send/data/transfer_client_service_test.dart`

### Implementation for User Story 1

- [x] T018 [P] [US1] Create `CompressionService` with `computeChecksum(path)` method in `lib/src/features/send/data/compression_service.dart`
- [x] T019 [P] [US1] Create `FilePickerService` with `pickFiles()` method in `lib/src/features/send/data/file_picker_service.dart`
- [x] T020 [US1] Create `TransferClientService` with `handshake()` and `upload()` methods in `lib/src/features/send/data/transfer_client_service.dart`
- [x] T021 [US1] Create `FileSelectionController` with `pickFiles()` and `clear()` actions in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T022 [US1] Create `TransferController` with `send()`, `cancel()` actions and progress tracking in `lib/src/features/send/application/transfer_controller.dart`
- [x] T023 [US1] Add history recording to `TransferController` using `HistoryRepository.addEntry()` in `lib/src/features/send/application/transfer_controller.dart`
- [x] T024 [US1] Create unit test for `TransferController` single file flow in `test/features/send/application/transfer_controller_test.dart`

**Checkpoint**: User Story 1 complete - single file transfer works end-to-end

---

## Phase 4: User Story 2 - Send Folder as ZIP (Priority: P1)

**Goal**: Select a folder, compress to ZIP, send with directory structure preserved

**Independent Test**: Select folder → verify compression → send → verify receiver extracts with correct structure

### Tests for User Story 2

- [x] T025 [P] [US2] Create unit test for `CompressionService.compressFolder` in `test/features/send/data/compression_service_test.dart`
- [x] T026 [P] [US2] Create unit test for `CompressionService.cleanup` in `test/features/send/data/compression_service_test.dart`

### Implementation for User Story 2

- [x] T027 [US2] Add `compressFolder(path)` method to `CompressionService` in `lib/src/features/send/data/compression_service.dart`
- [x] T028 [US2] Add `cleanup(path)` method to `CompressionService` in `lib/src/features/send/data/compression_service.dart`
- [x] T029 [US2] Add `pickFolder()` method to `FilePickerService` in `lib/src/features/send/data/file_picker_service.dart`
- [x] T030 [US2] Add `pickFolder()` action to `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T031 [US2] Update `TransferController` to handle folder preparation (compress, isFolder=true) in `lib/src/features/send/application/transfer_controller.dart`
- [x] T032 [US2] Add temp file cleanup after transfer (success/failure) to `TransferController` in `lib/src/features/send/application/transfer_controller.dart`

**Checkpoint**: User Story 2 complete - folder transfer with ZIP compression works

---

## Phase 5: User Story 3 - Send Text Content (Priority: P2)

**Goal**: Paste text and send as .txt file to receiver

**Independent Test**: Paste text → verify appears in selection → send → verify receiver gets .txt with exact content

### Tests for User Story 3

- [x] T033 [P] [US3] Create unit test for `FileSelectionController.pasteText` in `test/features/send/application/file_selection_controller_test.dart`

### Implementation for User Story 3

- [x] T034 [US3] Add `pasteText(String text)` action to `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T035 [US3] Add text-to-file conversion with generated filename ("Pasted Text - [timestamp].txt") in `TransferController` in `lib/src/features/send/application/transfer_controller.dart`

**Checkpoint**: User Story 3 complete - text transfer works

---

## Phase 6: User Story 4 - Manage Selection (Priority: P2)

**Goal**: View, clear, and remove individual items from selection queue

**Independent Test**: Add multiple items → verify list → remove one → verify updated → clear all → verify empty

### Tests for User Story 4

- [x] T036 [P] [US4] Create unit test for `FileSelectionController.removeItem` in `test/features/send/application/file_selection_controller_test.dart`
- [x] T037 [P] [US4] Create unit test for multi-item selection state in `test/features/send/application/file_selection_controller_test.dart`

### Implementation for User Story 4

- [x] T038 [US4] Add `removeItem(String id)` action to `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T039 [US4] Ensure `FileSelectionController` exposes selection list with type/path/preview for UI in `lib/src/features/send/application/file_selection_controller.dart`

**Checkpoint**: User Story 4 complete - full selection management works

---

## Phase 7: Multi-Item & Error Handling (Cross-Cutting)

**Purpose**: Sequential multi-item transfer with partial failure handling

### Tests

- [x] T040 [P] Create unit test for sequential multi-item transfer in `test/features/send/application/transfer_controller_test.dart`
- [x] T041 [P] Create unit test for partial failure (continue on error) in `test/features/send/application/transfer_controller_test.dart`
- [x] T042 [P] Create unit test for cancellation with cleanup in `test/features/send/application/transfer_controller_test.dart`

### Implementation

- [x] T043 Update `TransferController.send()` to handle multiple items sequentially in `lib/src/features/send/application/transfer_controller.dart`
- [x] T044 Add partial failure handling (continue with remaining, report summary) to `TransferController` in `lib/src/features/send/application/transfer_controller.dart`
- [x] T045 Add `retry(List<SelectedItem> failedItems)` action to `TransferController` in `lib/src/features/send/application/transfer_controller.dart`
- [x] T046 Add cancellation with `CancelToken` and temp file cleanup to `TransferController` in `lib/src/features/send/application/transfer_controller.dart`

**Checkpoint**: All multi-item and error handling scenarios work

---

## Phase 8: Polish & Integration

**Purpose**: Final integration, edge cases, and cleanup

- [x] T047 [P] Add error handling for file not found (deleted before transfer) in `TransferController`
- [x] T048 [P] Add error handling for handshake rejection (busy, insufficient_storage) in `TransferController`
- [x] T049 [P] Add user-friendly error messages for all failure cases in `TransferController`
- [x] T050 Run all tests: `fvm flutter test test/features/send/`
- [x] T051 Run static analysis: `fvm dart analyze lib/src/features/send/`
- [ ] T052 Validate quickstart.md manual test flow against implementation

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ───────────────────────────────────────────────────────────────>
         └──> Phase 2 (Foundational) ──────────────────────────────────────────>
                       └──> Phase 3 (US1: Single File) ────────────────────────>
                       └──> Phase 4 (US2: Folder) ─────────────────────────────>
                       └──> Phase 5 (US3: Text) ───────────────────────────────>
                       └──> Phase 6 (US4: Selection) ──────────────────────────>
                                     └──> Phase 7 (Multi-Item) ────────────────>
                                                └──> Phase 8 (Polish) ─────────>
```

### User Story Dependencies

| Story | Depends On | Notes |
|-------|------------|-------|
| US1 (Single File) | Phase 2 only | MVP - can ship after this |
| US2 (Folder) | Phase 2 only | Independent of US1 |
| US3 (Text) | Phase 2 only | Independent of US1, US2 |
| US4 (Selection) | Phase 2 only | Independent, but enhances all stories |
| Multi-Item | US1 complete | Builds on single-item transfer |

### Parallel Opportunities

**Phase 2** - All domain models (T004-T013) can run in parallel

**Phase 3** - Tests T015-T017 in parallel; Services T018-T019 in parallel

**Phases 3-6** - User Stories can be developed in parallel by different developers:
- Developer A: US1 (Single File)
- Developer B: US2 (Folder)
- Developer C: US3 (Text) + US4 (Selection)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# All domain models can be created simultaneously:
T004: SelectedItemType enum
T005: SelectedItem freezed
T006: TransferPayload freezed
T007: TransferResult freezed
T008: TransferPhase enum
T009: TransferProgress freezed
T011: HandshakeRequest DTO
T012: HandshakeResponse DTO
T013: UploadResponse DTO

# Then T010 (TransferState uses TransferProgress)
# Then T014 (build_runner generates all)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T014)
3. Complete Phase 3: User Story 1 (T015-T024)
4. **STOP and VALIDATE**: Test single file transfer end-to-end
5. Deploy/demo if ready

### Incremental Delivery

| Increment | Stories | Value Delivered |
|-----------|---------|-----------------|
| MVP | US1 | Single file transfer |
| v1.1 | US1 + US2 | + Folder transfer |
| v1.2 | US1-US3 | + Text sharing |
| v1.3 | US1-US4 | + Selection management |
| v2.0 | All + Multi-Item | Full feature with multi-select |

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 52 |
| **Setup Tasks** | 3 |
| **Foundational Tasks** | 11 |
| **US1 Tasks** | 10 |
| **US2 Tasks** | 8 |
| **US3 Tasks** | 3 |
| **US4 Tasks** | 4 |
| **Multi-Item Tasks** | 7 |
| **Polish Tasks** | 6 |
| **Parallelizable Tasks** | 26 (50%) |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to user story for traceability
- Tests written FIRST, then implementation
- Run build_runner after creating freezed models (T014)
- Commit after each task or logical group
- Stop at any checkpoint to validate independently

