# Tasks: Server Background Isolate Refactor

**Input**: Design documents from `/specs/009-server-background-isolate/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Constitution requires 90% coverage. Test tasks included.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Ensure code generation is ready for new Freezed models

- [x] T001 Run `dart run build_runner build --delete-conflicting-outputs` to verify code generation works
- [x] T002 Verify existing domain models compile in `lib/src/features/receive/domain/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create domain models required by ALL user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Domain Models

- [x] T003 [P] Create IsolateConfig model in `lib/src/features/receive/domain/isolate_config.dart`
- [x] T004 [P] Create IsolateCommand sealed class in `lib/src/features/receive/domain/isolate_command.dart`
- [x] T005 [P] Create IsolateEvent sealed class in `lib/src/features/receive/domain/isolate_event.dart`
- [x] T006 Update SessionStatus enum (pending→awaitingAccept, add accepted/cancelled) in `lib/src/features/receive/domain/session_status.dart`
- [x] T007 Update TransferSession to add requestId and state transitions in `lib/src/features/receive/domain/transfer_session.dart`
- [x] T008 Run `dart run build_runner build --delete-conflicting-outputs` to generate Freezed code

**Checkpoint**: Domain models ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Receive Files Without UI Freezing (Priority: P1) 🎯 MVP

**Goal**: Run HTTP server in separate isolate so UI remains responsive during file transfers

**Independent Test**: Start server on Android, send large file from another device, verify UI animations remain smooth throughout transfer

### Tests for User Story 1

- [x] T009 [P] [US1] Create unit test for ServerIsolateManager lifecycle in `test/features/receive/data/server_isolate_manager_test.dart`
- [x] T010 [P] [US1] Create serialization tests for IsolateCommand in `test/features/receive/domain/isolate_command_test.dart`
- [x] T011 [P] [US1] Create serialization tests for IsolateEvent in `test/features/receive/domain/isolate_event_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Create ServerIsolateManager class in `lib/src/features/receive/data/server_isolate_manager.dart`
- [x] T013 [US1] Implement isolate spawn with bidirectional SendPort setup in `server_isolate_manager.dart`
- [x] T014 [US1] Implement start() method with IsolateConfig passing in `server_isolate_manager.dart`
- [x] T015 [US1] Implement stop() method with graceful shutdown in `server_isolate_manager.dart`
- [x] T016 [US1] Implement event stream broadcasting in `server_isolate_manager.dart`
- [x] T017 [US1] Create server isolate entry point function in `lib/src/features/receive/data/server_isolate_entry.dart`
- [x] T018 [US1] Port Shelf HTTP server setup to isolate entry point in `server_isolate_entry.dart`
- [x] T019 [US1] Implement command receiving and routing in isolate entry point in `server_isolate_entry.dart`
- [x] T020 [US1] Create Riverpod provider for ServerIsolateManager in `lib/src/features/receive/data/server_isolate_manager.dart` (combined with manager)

**Checkpoint**: Server runs in isolate, Android socket creation verified, UI stays responsive

---

## Phase 4: User Story 2 - Accept or Reject Incoming File Requests (Priority: P1)

**Goal**: Show sender info and file details, let user accept or reject transfer

**Independent Test**: Initiate handshake from another device, verify accept/reject dialog appears with correct info

### Tests for User Story 2

- [ ] T021 [P] [US2] Create unit test for handshake flow with Completer pattern in `test/features/receive/data/handshake_handler_test.dart`
- [ ] T022 [P] [US2] Create test for Quick Save auto-accept in `test/features/receive/data/handshake_handler_test.dart`

### Implementation for User Story 2

- [x] T023 [US2] Implement Completer-based pending request tracking in `server_isolate_entry.dart`
- [x] T024 [US2] Implement handshake endpoint with deferred response in `server_isolate_entry.dart`
- [x] T025 [US2] Implement 60-second timeout with auto-reject in `server_isolate_entry.dart`
- [x] T026 [US2] Implement RespondHandshake command handling in `server_isolate_entry.dart`
- [x] T027 [US2] Implement Quick Save auto-accept logic (skip Completer when enabled) in `server_isolate_entry.dart`
- [x] T028 [US2] Emit IncomingRequest event with requestId to main isolate in `server_isolate_entry.dart`
- [x] T029 [US2] Update ServerController to call sendCommand for accept/reject in `lib/src/features/receive/application/server_controller.dart`

**Checkpoint**: Handshake flow works, accept/reject reaches sender, Quick Save auto-accepts

---

## Phase 5: User Story 3 - Monitor Transfer Progress in Real-Time (Priority: P2)

**Goal**: Show real-time progress updates during file transfer without flooding UI

**Independent Test**: Send large file, verify progress percentage updates every ~500ms without lag

### Tests for User Story 3

- [ ] T030 [P] [US3] Create unit test for progress throttling (max 10 updates/sec) in `test/features/receive/data/progress_throttle_test.dart`

### Implementation for User Story 3

- [x] T031 [US3] Implement time-based progress throttling (100ms interval) in `server_isolate_entry.dart`
- [x] T032 [US3] Emit TransferProgress events during file upload in `server_isolate_entry.dart`
- [x] T033 [US3] Ensure final progress (100%) is always emitted on completion in `server_isolate_entry.dart`
- [x] T034 [US3] Update ServerController to map TransferProgress to UI state in `lib/src/features/receive/application/server_controller.dart`

**Checkpoint**: Progress updates appear in UI, throttled to 10/sec, completion is always reported

---

## Phase 6: User Story 4 - Handle Server Errors Gracefully (Priority: P2)

**Goal**: Show clear error messages for server failures (port busy, network error, disk full)

**Independent Test**: Bind to busy port, verify appropriate error message appears in UI

### Tests for User Story 4

- [ ] T035 [P] [US4] Create unit test for port binding failure handling in `test/features/receive/data/server_isolate_manager_test.dart`
- [ ] T036 [P] [US4] Create unit test for transfer failure cleanup in `test/features/receive/data/server_isolate_manager_test.dart`

### Implementation for User Story 4

- [x] T037 [US4] Implement port binding error detection and ServerError event in `server_isolate_entry.dart`
- [x] T038 [US4] Implement disk full detection during file write in `server_isolate_entry.dart`
- [x] T039 [US4] Implement sender disconnect detection and TransferFailed event in `server_isolate_entry.dart`
- [x] T040 [US4] Implement partial file cleanup on transfer failure in `server_isolate_entry.dart`
- [x] T041 [US4] Update ServerController to map error events to UI messages in `lib/src/features/receive/application/server_controller.dart`

**Checkpoint**: Errors display meaningful messages, partial files are cleaned up

---

## Phase 7: User Story 5 - Server Lifecycle Management (Priority: P3)

**Goal**: Server continues running when navigating away or app is minimized

**Independent Test**: Start server, navigate to Settings, verify server still accepts connections

### Tests for User Story 5

- [ ] T042 [P] [US5] Create unit test for isolate crash detection in `test/features/receive/data/server_isolate_manager_test.dart`

### Implementation for User Story 5

- [x] T043 [US5] Implement isolate crash detection via onExit callback in `lib/src/features/receive/data/server_isolate_manager.dart`
- [x] T044 [US5] Emit ServerError event on unexpected isolate termination in `server_isolate_manager.dart`
- [x] T045 [US5] Ensure ServerController maintains subscription across navigation in `lib/src/features/receive/application/server_controller.dart`
- [ ] T046 [US5] Verify server state is correctly reflected when returning to Receive screen

**Checkpoint**: Server persists across navigation, crash is detected and reported

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Integration, cleanup, and validation

- [ ] T047 Remove prototype isolate code from `lib/src/features/receive/data/file_server_service.dart`
- [ ] T048 Update FileServerService to delegate to ServerIsolateManager in `file_server_service.dart`
- [x] T049 Run `flutter analyze` and fix all lint errors
- [x] T050 Run all tests with `flutter test test/features/receive/`
- [ ] T051 Validate quickstart.md scenarios on Android device
- [ ] T052 Verify OS-level socket visible via `adb shell netstat` on Android

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 and tightly coupled (handshake is part of receive flow)
  - US3 and US4 are P2, can start after US1/US2 complete
  - US5 is P3, can start after US1 complete
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Priority | Depends On | Notes |
|-------|----------|------------|-------|
| US1 | P1 | Foundational | Core isolate infrastructure |
| US2 | P1 | US1 | Handshake requires isolate running |
| US3 | P2 | US1, US2 | Progress requires active transfer |
| US4 | P2 | US1 | Error handling for isolate |
| US5 | P3 | US1 | Lifecycle requires isolate running |

### Parallel Opportunities

Within each phase, tasks marked [P] can run in parallel:
- **Phase 2**: T003, T004, T005 (domain models)
- **Phase 3**: T009, T010, T011 (tests)
- **Phase 5**: T030 (test)
- **Phase 6**: T035, T036 (tests)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all domain models in parallel:
Task: "Create IsolateConfig model in lib/src/features/receive/domain/isolate_config.dart"
Task: "Create IsolateCommand sealed class in lib/src/features/receive/domain/isolate_command.dart"
Task: "Create IsolateEvent sealed class in lib/src/features/receive/domain/isolate_event.dart"

# Then sequentially:
Task: "Update SessionStatus enum in lib/src/features/receive/domain/session_status.dart"
Task: "Update TransferSession to add requestId in lib/src/features/receive/domain/transfer_session.dart"
Task: "Run dart run build_runner build"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (isolate infrastructure)
4. Complete Phase 4: User Story 2 (handshake flow)
5. **STOP and VALIDATE**: Test on Android device - socket visible, accept/reject works
6. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Domain models ready
2. Add US1 → Server runs in isolate → Verify Android socket
3. Add US2 → Handshake works → Accept/reject flows correctly
4. Add US3 → Progress updates → UI shows transfer %
5. Add US4 → Error handling → Meaningful error messages
6. Add US5 → Lifecycle → Survives navigation
7. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US1 and US2 are both P1 and should be completed together for MVP
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Key verification: `adb shell netstat -tlnp | grep 53318` shows socket on Android

