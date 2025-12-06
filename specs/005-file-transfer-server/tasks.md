# Tasks: File Transfer Server (Receive Logic)

**Input**: Design documents from `/specs/005-file-transfer-server/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Constitution requires 90% test coverage. Unit tests are included for Application and Data layers per constitution guidelines.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/features/receive/`, `test/features/receive/` at repository root
- Follows Riverpod Architecture (Feature-First) per constitution

---

## Phase 1: Setup (Dependencies & Configuration)

**Purpose**: Install dependencies and configure platform settings

- [x] T001 Add shelf and shelf_router dependencies via `fvm flutter pub add shelf shelf_router`
- [x] T002 Add crypto dependency via `fvm flutter pub add crypto`
- [x] T003 Add archive dependency via `fvm flutter pub add archive`
- [x] T004 Add uuid dependency via `fvm flutter pub add uuid`
- [x] T005 [P] Add macOS network server entitlement to `macos/Runner/DebugProfile.entitlements` (add `com.apple.security.network.server` key)
- [x] T006 [P] Add macOS network server entitlement to `macos/Runner/Release.entitlements` (add `com.apple.security.network.server` key)
- [x] T007 Create feature directory structure: `lib/src/features/receive/domain/`, `lib/src/features/receive/data/`, `lib/src/features/receive/application/`
- [x] T008 Create test directory structure: `test/features/receive/application/`, `test/features/receive/data/`

---

## Phase 2: Foundational (Domain Models - Shared by All Stories)

**Purpose**: Core data models that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T009 [P] Create SessionStatus enum in `lib/src/features/receive/domain/session_status.dart` with values: pending, receiving, completed, failed, expired
- [x] T010 [P] Create TransferMetadata Freezed model in `lib/src/features/receive/domain/transfer_metadata.dart` with fields: fileName, fileSize, fileType, checksum, isFolder, fileCount, senderDeviceId, senderAlias
- [x] T011 [P] Create TransferProgress Freezed model in `lib/src/features/receive/domain/transfer_progress.dart` with fields: bytesReceived, totalBytes, startedAt and computed percentComplete
- [x] T012 Create TransferSession Freezed model in `lib/src/features/receive/domain/transfer_session.dart` with fields: sessionId, metadata, createdAt, status (depends on T009, T010)
- [x] T013 Create ServerState Freezed model in `lib/src/features/receive/domain/server_state.dart` with fields: isRunning, port, isBroadcasting, activeSession, transferProgress, error (depends on T011, T012)
- [x] T014 [P] Create TransferEvent sealed class hierarchy in `lib/src/features/receive/domain/transfer_event.dart` with HandshakeReceived, UploadStarted, UploadProgress, UploadCompleted, UploadFailed events
- [x] T015 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to generate Freezed code

**Checkpoint**: Domain models ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Receive Single File (Priority: P1) 🎯 MVP

**Goal**: Accept and save an incoming file from another device on the same network

**Independent Test**: Start server, send handshake via HTTP, send file via upload endpoint, verify file saved to Downloads with correct checksum

### Unit Tests for User Story 1

- [x] T016 [P] [US1] Create FileStorageService test file `test/features/receive/data/file_storage_service_test.dart` with tests for: getReceiveFolder, resolveFilename collision handling, writeStream, deleteFile, getAvailableSpace
- [x] T017 [P] [US1] Create FileServerService test file `test/features/receive/data/file_server_service_test.dart` with tests for: start/stop server, handleHandshake (accept, reject busy, reject invalid), handleUpload (valid session, invalid session, checksum verify)

### Implementation for User Story 1

- [x] T018 [P] [US1] Implement FileStorageService in `lib/src/features/receive/data/file_storage_service.dart` with getReceiveFolder (platform-specific Downloads), resolveFilename (numeric suffix), getAvailableSpace
- [x] T019 [US1] Implement FileStorageService writeStream method with streaming file write and MD5 checksum computation (depends on T018)
- [x] T020 [US1] Implement FileStorageService deleteFile method for cleanup on failure (depends on T018)
- [x] T021 [US1] Create fileStorageServiceProvider in `lib/src/features/receive/data/file_storage_service.dart` using @riverpod annotation
- [x] T022 [US1] Implement FileServerService in `lib/src/features/receive/data/file_server_service.dart` with start/stop methods using shelf, Pipeline middleware, and Router setup
- [x] T023 [US1] Implement handleHandshake in FileServerService: parse JSON body, validate metadata (including required checksum), check busy state, check storage, generate session ID, return HandshakeResponse
- [x] T024 [US1] Implement handleUpload in FileServerService: validate X-Transfer-Session header, stream file to storage, compute checksum, verify against metadata, emit events (depends on T018-T21)
- [x] T025 [US1] Create fileServerServiceProvider in `lib/src/features/receive/data/file_server_service.dart` using @riverpod annotation
- [x] T026 [US1] Implement session management in FileServerService: Map<String, TransferSession> storage, 5-minute timeout Timer, expiration cleanup
- [x] T027 [US1] Add history integration in FileServerService: call historyRepositoryProvider.addEntry on upload completion/failure with TransferDirection.received

**Checkpoint**: User Story 1 data layer complete - single file receive via HTTP works

---

## Phase 4: User Story 2 - Toggle Server On/Off (Priority: P1) 🎯 MVP

**Goal**: Start and stop the file receive server with a single action, integrating with Discovery broadcast

**Independent Test**: Toggle server on → verify listening on port AND discovery broadcasting. Toggle off → verify server stopped AND broadcast stopped.

### Unit Tests for User Story 2

- [x] T028 [P] [US2] Create ServerController test file `test/features/receive/application/server_controller_test.dart` with tests for: build (initial state), startServer (success, discovery fail warning), stopServer, toggleServer, state transitions, clearError

### Implementation for User Story 2

- [x] T029 [US2] Implement ServerController as AsyncNotifier in `lib/src/features/receive/application/server_controller.dart` with ServerState, build method returning stopped state
- [x] T030 [US2] Implement startServer method in ServerController: start FileServerService, attempt DiscoveryController.startBroadcast, catch broadcast failure and log warning, update state (depends on T025)
- [x] T031 [US2] Implement stopServer method in ServerController: stop FileServerService, stop DiscoveryController.stopBroadcast if broadcasting, update state
- [x] T032 [US2] Implement toggleServer convenience method in ServerController (calls startServer or stopServer based on isRunning)
- [x] T033 [US2] Implement clearError method in ServerController
- [x] T034 [US2] Subscribe to FileServerService.events stream in ServerController to update activeSession and transferProgress state
- [x] T035 [US2] Create serverControllerProvider using @riverpod annotation in `lib/src/features/receive/application/server_controller.dart`
- [x] T036 [US2] Update receive_screen.dart to use serverControllerProvider for toggle button and server state display

**Checkpoint**: User Stories 1 AND 2 complete - Core MVP functional (receive files + toggle server)

---

## Phase 5: User Story 3 - Receive Folder/Multiple Files (Priority: P2)

**Goal**: Receive folders (as ZIP) or multiple files in a single transfer session

**Independent Test**: Send folder as ZIP stream, verify extraction with preserved directory structure

### Implementation for User Story 3

- [x] T037 [US3] Add extractZip method to FileStorageService in `lib/src/features/receive/data/file_storage_service.dart` using archive package
- [x] T038 [US3] Update handleUpload in FileServerService to check metadata.isFolder flag and call extractZip after successful write
- [x] T039 [US3] Add test cases for ZIP extraction in `test/features/receive/data/file_storage_service_test.dart`: extract preserves structure, handles nested folders

**Checkpoint**: User Story 3 complete - Folder transfers work

---

## Phase 6: User Story 4 - View Transfer Status (Priority: P2)

**Goal**: Display current status of ongoing transfer (Idle, Receiving with progress, Completed)

**Independent Test**: Observe UI status changes as transfer progresses: Idle → Receiving (with percentage) → Completed

### Implementation for User Story 4

- [x] T040 [US4] Update receive_screen.dart to display transfer status from ServerController state: idle/receiving/completed text
- [x] T041 [US4] Add progress indicator to receive_screen.dart showing transferProgress.percentComplete when receiving
- [x] T042 [US4] Add sender info display to receive_screen.dart showing activeSession.metadata.senderAlias during transfer
- [x] T043 [US4] Add completed transfer info display: filename, size, saved path (visible briefly after completion)

**Checkpoint**: All user stories complete

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T044 [P] Run all unit tests: `fvm flutter test test/features/receive/`
- [x] T045 [P] Run static analysis: `fvm flutter analyze lib/src/features/receive/`
- [ ] T046 Validate quickstart.md scenarios manually: start server, send file via curl, verify saved
- [x] T047 Run full build: `fvm flutter build macos` (or appropriate platform)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on Foundational phase; integrates with US1's FileServerService
- **User Story 3 (Phase 5)**: Depends on US1 completion (extends FileServerService)
- **User Story 4 (Phase 6)**: Depends on US2 completion (uses ServerController state)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (Receive Single File) | Foundational | None (first) |
| US2 (Toggle Server) | Foundational, uses US1 FileServerService | Partial - tests can parallel |
| US3 (Receive Folder) | US1 | US4 (different files) |
| US4 (View Status) | US2 | US3 (different files) |

### Within Each User Story

- Tests MUST be written and FAIL before implementation begins
- Domain models before Data services
- Data services before Application controllers
- Application layer before Presentation updates
- Story complete before moving to next priority

---

## Parallel Opportunities

### Phase 2 (Foundational) - All models in parallel:

```bash
# Can run T009, T010, T011, T014 in parallel (different files, no deps)
```

### Phase 3 (US1) - Tests and storage in parallel:

```bash
# T016, T017 can run in parallel (different test files)
# T018 can start with tests (different files)
```

### Phase 5 & 6 - Can overlap:

```bash
# US3 (T037-T039) and US4 (T040-T043) can proceed in parallel
# US3 modifies FileServerService/FileStorageService
# US4 modifies receive_screen.dart (different files)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T015)
3. Complete Phase 3: User Story 1 - Receive Single File (T016-T027)
4. Complete Phase 4: User Story 2 - Toggle Server (T028-T036)
5. **STOP and VALIDATE**: Test via curl commands in quickstart.md
6. Merge/deploy MVP

### Incremental Delivery

After MVP:
- Add User Story 3 (Folder transfers) → Test → Deploy
- Add User Story 4 (Status display) → Test → Deploy

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Constitution requires 90% test coverage - unit tests included
- Verify tests fail before implementing each component
- Commit after each task or logical group
- Run `build_runner` after creating new Freezed models

