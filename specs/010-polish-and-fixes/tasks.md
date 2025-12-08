# Tasks: Polish and Bug Fixes

**Input**: Design documents from `/specs/010-polish-and-fixes/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Not explicitly requested - test tasks are omitted. Manual verification steps provided in quickstart.md.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/core/`, `lib/src/features/`, `test/` at repository root

---

## Phase 1: Setup

**Purpose**: Add new dependencies required for this feature

- [x] T001 Add `permission_handler` package to `pubspec.yaml` using `flutter pub add permission_handler`
- [x] T002 Run `flutter pub get` to install dependencies
- [x] T003 Run `dart run build_runner build` to regenerate Freezed/Riverpod code after model changes

---

## Phase 2: Foundational (Shared Models & Utilities)

**Purpose**: Create new models and utilities that multiple user stories depend on

**⚠️ CRITICAL**: Complete before starting any user story

- [x] T004 [P] Create `PendingTransferRequest` model in `lib/src/features/receive/domain/pending_transfer_request.dart` (freezed class with requestId, senderAlias, senderDeviceId, fileName, fileSize, fileType, isFolder, fileCount, receivedAt)
- [x] T005 [P] Create `TransferStatusBarState` model inline in `lib/src/core/widgets/transfer_status_bar.dart` (freezed class with isVisible, isSending, fileName, bytesTransferred, totalBytes, progress, peerName)
- [x] T006 [P] Create `PermissionController` provider in `lib/src/core/providers/permission_provider.dart` (check/request storage permission using permission_handler)
- [x] T007 Modify `DeviceIdentity` in `lib/src/features/receive/domain/device_identity.dart` to make `port` nullable (int? instead of int)
- [x] T008 Modify `ServerState` in `lib/src/features/receive/domain/server_state.dart` to add `pendingRequest` (PendingTransferRequest?) and `pendingRequestTimeout` (DateTime?) fields
- [x] T009 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate all Freezed code

**Checkpoint**: All new models and providers created - user story implementation can begin

---

## Phase 3: User Story 1 - Server Stability and Reliability (Priority: P1) 🎯 MVP

**Goal**: Fix server isolate handshake timeout and stream close errors

**Independent Test**: Start the app, enable receive mode, verify server starts successfully 10 consecutive times without errors.

### Implementation for User Story 1

- [x] T010 [US1] Add `_disposed` flag to `ServerIsolateManager` in `lib/src/features/receive/data/server_isolate_manager.dart` initialized to false
- [x] T011 [US1] Update `_handleIsolateMessage()` in `lib/src/features/receive/data/server_isolate_manager.dart` to check `_disposed || _eventController.isClosed` before adding events
- [x] T012 [US1] Update `dispose()` in `lib/src/features/receive/data/server_isolate_manager.dart` to set `_disposed = true` first, then cancel `_receivePortSubscription`, then close `_eventController`
- [x] T013 [US1] Update `_cleanup()` and `_cleanupWithoutKill()` in `lib/src/features/receive/data/server_isolate_manager.dart` to follow same disposal order
- [x] T014 [US1] Increase handshake timeout from 10 seconds to 30 seconds in `lib/src/features/receive/data/server_isolate_manager.dart`
- [x] T015 [US1] Add retry logic (3 attempts with exponential backoff) for handshake in `lib/src/features/receive/data/server_isolate_manager.dart`
- [x] T016 [US1] Add detailed logging for timeout diagnostics in `lib/src/features/receive/data/server_isolate_manager.dart`

**Checkpoint**: Server starts reliably without stream close or timeout errors

---

## Phase 4: User Story 2 - Accept/Decline Incoming Transfers (Priority: P1)

**Goal**: Show bottom sheet to accept/decline transfers when Quick Save is off

**Independent Test**: Disable Quick Save, send file from another device, verify bottom sheet appears with accept/decline.

### Implementation for User Story 2

- [x] T017 [P] [US2] Create `PendingRequestSheet` widget in `lib/src/features/receive/presentation/widgets/pending_request_sheet.dart` displaying sender, fileName, fileSize with Accept/Decline buttons
- [x] T018 [US2] Add countdown timer (30 seconds) with visual indicator to `PendingRequestSheet` in `lib/src/features/receive/presentation/widgets/pending_request_sheet.dart`
- [x] T019 [US2] Update `ServerController` in `lib/src/features/receive/application/server_controller.dart` to create `PendingTransferRequest` when handshake arrives and Quick Save is off
- [x] T020 [US2] Add `acceptPendingRequest(String requestId)` method to `ServerController` in `lib/src/features/receive/application/server_controller.dart`
- [x] T021 [US2] Add `declinePendingRequest(String requestId)` method to `ServerController` in `lib/src/features/receive/application/server_controller.dart`
- [x] T022 [US2] Update `ReceiveScreen` in `lib/src/features/receive/presentation/receive_screen.dart` to show `PendingRequestSheet` bottom sheet when `serverState.pendingRequest` is not null
- [x] T023 [US2] Implement auto-decline timeout (30s) in `ServerController` in `lib/src/features/receive/application/server_controller.dart`

**Checkpoint**: Accept/decline bottom sheet appears for incoming transfers when Quick Save is off

---

## Phase 5: User Story 3 - Transfer Progress Visibility (Priority: P2)

**Goal**: Show dedicated status bar with transfer progress on both Send and Receive screens

**Independent Test**: Send large file (>10MB), verify progress bar visible on both devices.

### Implementation for User Story 3

- [x] T024 [P] [US3] Create `TransferStatusBar` widget in `lib/src/core/widgets/transfer_status_bar.dart` with progress bar, file name, percentage, bytes transferred
- [x] T025 [P] [US3] Create `transferStatusBarProvider` in `lib/src/core/widgets/transfer_status_bar.dart` watching serverController and transferController for progress
- [x] T026 [US3] Add `TransferStatusBar` to `ReceiveScreen` in `lib/src/features/receive/presentation/receive_screen.dart` (fixed position at bottom)
- [x] T027 [US3] Add `TransferStatusBar` to `SendScreen` in `lib/src/features/send/presentation/send_screen.dart` (fixed position at bottom)
- [x] T028 [US3] Add slide-in/out animation to `TransferStatusBar` in `lib/src/core/widgets/transfer_status_bar.dart`

**Checkpoint**: Progress bar visible during transfers on both sender and receiver screens

---

## Phase 6: User Story 4 - Transfer Completion Notifications (Priority: P2)

**Goal**: Show toast notifications when transfers complete or fail

**Independent Test**: Complete transfer, verify toast appears on both devices.

### Implementation for User Story 4

- [x] T029 [P] [US4] Create `showSuccessToast()` helper function in `lib/src/core/widgets/toast_helper.dart` using ScaffoldMessenger
- [x] T030 [P] [US4] Create `showErrorToast()` helper function in `lib/src/core/widgets/toast_helper.dart` using ScaffoldMessenger
- [x] T031 [US4] Add success toast on transfer completion in `ReceiveScreen` in `lib/src/features/receive/presentation/receive_screen.dart`
- [x] T032 [US4] Add success toast on transfer completion in `SendScreen` in `lib/src/features/send/presentation/send_screen.dart`
- [x] T033 [US4] Add error toast on transfer failure in `ReceiveScreen` in `lib/src/features/receive/presentation/receive_screen.dart`
- [x] T034 [US4] Add error toast on transfer failure in `SendScreen` in `lib/src/features/send/presentation/send_screen.dart`

**Checkpoint**: Toast notifications appear on transfer completion/failure

---

## Phase 7: User Story 5 - Send History Recording (Priority: P2)

**Goal**: Fix send history not being recorded properly

**Independent Test**: Send files to different devices, verify all appear in history with "Sent" direction.

### Implementation for User Story 5

- [x] T035 [US5] Add debug logging to `_recordHistory()` method in `lib/src/features/send/application/transfer_controller.dart` to verify it's called
- [x] T036 [US5] Verify `_recordHistory()` is called on all transfer completion paths (success and failure) in `lib/src/features/send/application/transfer_controller.dart`
- [x] T037 [US5] Add try-catch with logging around database write in `_recordHistory()` in `lib/src/features/send/application/transfer_controller.dart`
- [x] T038 [US5] Verify history query in `HistoryRepository` in `lib/src/features/history/data/history_repository.dart` returns both sent and received entries

**Checkpoint**: Send history entries appear correctly in history screen

---

## Phase 8: User Story 6 - Storage Permission Handling (Priority: P2)

**Goal**: Request storage permission on Android before saving files

**Independent Test**: Fresh install, receive file, verify permission dialog appears.

### Implementation for User Story 6

- [x] T039 [US6] Implement `checkStoragePermission()` in `PermissionController` in `lib/src/core/providers/permission_provider.dart`
- [x] T040 [US6] Implement `requestStoragePermission()` in `PermissionController` in `lib/src/core/providers/permission_provider.dart`
- [x] T041 [US6] Update `ServerController` in `lib/src/features/receive/application/server_controller.dart` to check/request permission before saving file
- [x] T042 [US6] Add permission denied error handling with user-friendly toast in `lib/src/features/receive/application/server_controller.dart`
- [x] T043 [US6] Update Android-specific permission config if needed in `android/app/build.gradle` for permission_handler (already configured in AndroidManifest.xml)

**Checkpoint**: Storage permission requested on Android, graceful handling of denial

---

## Phase 9: User Story 7 - Device Discovery Persistence (Priority: P3)

**Goal**: Keep discovered devices visible for at least 2 minutes

**Independent Test**: Discover device, wait 2+ minutes, verify it remains visible.

### Implementation for User Story 7

- [x] T044 [US7] Increase `_stalenessTimeout` to 2 minutes (120 seconds) in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T045 [US7] Add logging when devices are pruned in `_pruneStaleDevices()` in `lib/src/features/discovery/application/discovery_controller.dart`
- [-] T046 [US7] Consider adding periodic liveness check (optional - ping devices every 60s) in `lib/src/features/discovery/application/discovery_controller.dart` (skipped - 2 min timeout is sufficient)

**Checkpoint**: Devices remain visible for 2+ minutes while on network

---

## Phase 10: User Story 8 - Correct Port Display (Priority: P3)

**Goal**: Show actual server port in IdentityCard instead of hardcoded 8080

**Independent Test**: Start receive mode, verify IdentityCard shows port 53318 (or actual port).

### Implementation for User Story 8

- [x] T047 [US8] Update `IdentityCard` widget in `lib/src/features/receive/presentation/widgets/identity_card.dart` to accept optional `actualPort` parameter
- [x] T048 [US8] Update `ReceiveScreen` in `lib/src/features/receive/presentation/receive_screen.dart` to pass `serverState.port` to `IdentityCard` when server is running (done via watching serverControllerProvider directly in IdentityCard)
- [x] T049 [US8] Update port display logic in `IdentityCard` in `lib/src/features/receive/presentation/widgets/identity_card.dart` to show "Not running" when port is null (shows fallback port instead)

**Checkpoint**: IdentityCard shows actual server port (53318) when running

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and validation

- [x] T050 Run `dart analyze` to ensure no lint warnings in modified files
- [x] T051 Run `dart format .` to ensure consistent formatting
- [x] T052 Verify all Freezed code is regenerated with `dart run build_runner build`
- [ ] T053 Run manual test checklist from `specs/010-polish-and-fixes/quickstart.md`
- [ ] T054 Test on Android device to verify storage permission flow
- [ ] T055 Test rapid server start/stop (10 times) to verify no stream errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-10)**: All depend on Foundational phase completion
  - US1 (Server Stability): **Do first** - fixes blocking bugs
  - US2 (Accept/Decline): Depends on US1 being stable
  - US3-US8: Can proceed in parallel after US1
- **Polish (Phase 11)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (P1) | Foundational | None - do first |
| US2 (P1) | US1 | None - needs stable server |
| US3 (P2) | Foundational | US4, US5, US6, US7, US8 |
| US4 (P2) | Foundational | US3, US5, US6, US7, US8 |
| US5 (P2) | Foundational | US3, US4, US6, US7, US8 |
| US6 (P2) | Foundational | US3, US4, US5, US7, US8 |
| US7 (P3) | Foundational | US3, US4, US5, US6, US8 |
| US8 (P3) | Foundational | US3, US4, US5, US6, US7 |

### Within Each User Story

- Models before providers
- Providers before UI widgets
- Core implementation before integration
- Each story independently testable

---

## Parallel Execution Examples

### Phase 2 Parallel Tasks

```bash
# These can run in parallel (different files):
T004: PendingTransferRequest model
T005: TransferStatusBarState model
T006: PermissionController provider
```

### User Story 3 + 4 Parallel

```bash
# After Foundational complete, these stories can run in parallel:
# Story 3: T024, T025, T026, T027, T028
# Story 4: T029, T030, T031, T032, T033, T034
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2)

1. Complete Phase 1: Setup (add permission_handler)
2. Complete Phase 2: Foundational (create models)
3. Complete Phase 3: US1 - Server Stability (**Critical bug fixes**)
4. Complete Phase 4: US2 - Accept/Decline (**Core UX feature**)
5. **STOP and VALIDATE**: Test server stability and accept/decline flow
6. Deploy/demo MVP

### Incremental Delivery

1. Setup + Foundational → Models ready
2. US1 (Server Stability) → No more crashes → Can receive files reliably
3. US2 (Accept/Decline) → User control over incoming transfers
4. US3 + US4 (Progress + Notifications) → Better user feedback
5. US5 (Send History) → Feature completeness
6. US6 (Storage Permission) → Android reliability
7. US7 + US8 (Discovery + Port) → Polish and minor fixes

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 55 |
| Setup Tasks | 3 |
| Foundational Tasks | 6 |
| US1 Tasks | 7 |
| US2 Tasks | 7 |
| US3 Tasks | 5 |
| US4 Tasks | 6 |
| US5 Tasks | 4 |
| US6 Tasks | 5 |
| US7 Tasks | 3 |
| US8 Tasks | 3 |
| Polish Tasks | 6 |
| Parallel Opportunities | 15+ tasks marked [P] |
| MVP Scope | US1 + US2 (17 tasks after foundational) |

---

## Notes

- [P] tasks = different files, no dependencies on each other
- [Story] label maps task to specific user story
- US1 must complete first (blocking bugs)
- US2 depends on stable server from US1
- US3-US8 can largely run in parallel
- Verify each checkpoint before proceeding
- Commit after each task or logical group

