# Tasks: Receive Tab UI

**Input**: Design documents from `/specs/007-receive-ui/`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, quickstart.md ✓

**Tests**: Not explicitly requested in spec - test tasks omitted (can be added later if needed)

**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths included in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Extend existing infrastructure with settings keys and IP address retrieval

- [x] T001 Add `receiveMode` and `quickSave` setting keys to `lib/src/features/settings/data/settings_repository.dart`
- [x] T002 Add `getReceiveMode()` and `setReceiveMode()` methods to SettingsRepository in `lib/src/features/settings/data/settings_repository.dart`
- [x] T003 Add `getQuickSave()` and `setQuickSave()` methods to SettingsRepository in `lib/src/features/settings/data/settings_repository.dart`
- [x] T004 Add `getLocalIpAddress()` method to DeviceInfoProvider in `lib/src/core/providers/device_info_provider.dart`
- [x] T005 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to regenerate providers

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models and providers that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 [P] Create ReceiveSettings freezed model in `lib/src/features/receive/domain/receive_settings.dart`
- [x] T007 [P] Create DeviceIdentity freezed model in `lib/src/features/receive/domain/device_identity.dart`
- [x] T008 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to generate freezed code
- [x] T009 Create receiveSettingsProvider in `lib/src/features/receive/application/receive_settings_provider.dart`
- [x] T010 Create deviceIdentityProvider in `lib/src/features/receive/application/device_identity_provider.dart`
- [x] T011 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to generate riverpod code
- [x] T012 Add `history` route constant to `lib/src/core/routing/routes.dart`
- [x] T013 Add `/receive/history` nested route to `lib/src/core/routing/app_router.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Device Identity (Priority: P1) 🎯 MVP

**Goal**: Display device identity information (avatar, alias, IP, port) in Identity Card

**Independent Test**: Open Receive tab → verify Identity Card shows avatar, alias, IP address, port. Tap IP → verify copied to clipboard with snackbar feedback.

### Implementation for User Story 1

- [x] T014 [P] [US1] Create PulsingAvatar widget in `lib/src/features/receive/presentation/widgets/pulsing_avatar.dart`
- [x] T015 [P] [US1] Create DeviceAvatar widget (icon based on device type) in `lib/src/features/receive/presentation/widgets/device_avatar.dart`
- [x] T016 [US1] Create IdentityCard widget displaying avatar, alias, IP, port in `lib/src/features/receive/presentation/widgets/identity_card.dart`
- [x] T017 [US1] Add tap-to-copy IP address with clipboard and snackbar feedback in IdentityCard
- [x] T018 [US1] Handle "Not Connected" state when IP is null in IdentityCard

**Checkpoint**: User Story 1 complete - Identity Card displays and copy-to-clipboard works

---

## Phase 4: User Story 2 - Toggle Receive Mode (Priority: P1)

**Goal**: Toggle receive mode on/off with visual feedback (pulse animation, status text) and server control

**Independent Test**: Toggle Receive Mode → verify pulse animation starts/stops, status text changes, server starts/stops

### Implementation for User Story 2

- [x] T019 [US2] Create ServerToggle widget with Switch and status text in `lib/src/features/receive/presentation/widgets/server_toggle.dart`
- [x] T020 [US2] Connect ServerToggle to receiveSettingsProvider for state management
- [x] T021 [US2] Connect ServerToggle to existing ServerController for server start/stop
- [x] T022 [US2] Add state persistence - load saved Receive Mode on app launch in receiveSettingsProvider
- [x] T023 [US2] Integrate PulsingAvatar animation with Receive Mode state (animate when ON)
- [x] T024 [US2] Display "Ready" status when ON and "Offline" status when OFF

**Checkpoint**: User Story 2 complete - Receive Mode toggle works with persistence and visual feedback

---

## Phase 5: User Story 3 - Toggle Quick Save Mode (Priority: P2)

**Goal**: Toggle Quick Save preference for auto-accepting transfers

**Independent Test**: Toggle Quick Save → close app → reopen → verify setting persisted

### Implementation for User Story 3

- [x] T025 [US3] Create QuickSaveSwitch widget in `lib/src/features/receive/presentation/widgets/quick_save_switch.dart`
- [x] T026 [US3] Connect QuickSaveSwitch to receiveSettingsProvider for state and persistence
- [x] T027 [US3] Add Quick Save persistence - load saved state on app launch

**Checkpoint**: User Story 3 complete - Quick Save toggle works with persistence

---

## Phase 6: User Story 4 - View Transfer History (Priority: P2)

**Goal**: Display transfer history in full-screen view with direction icons

**Independent Test**: Tap History button → verify HistoryScreen opens with transfer records (or empty state), sent/received icons visible, back navigation works

### Implementation for User Story 4

- [x] T028 [US4] Create HistoryListItem widget with direction icons in `lib/src/features/receive/presentation/widgets/history_list_item.dart`
- [x] T029 [US4] Create HistoryScreen with AppBar and back navigation in `lib/src/features/receive/presentation/history_screen.dart`
- [x] T030 [US4] Connect HistoryScreen to existing historyStreamProvider for live data
- [x] T031 [US4] Display empty state when no transfer records exist
- [x] T032 [US4] Show upward arrow icon for sent transfers, downward arrow for received

**Checkpoint**: User Story 4 complete - History view works with navigation and direction icons

---

## Phase 7: Integration (Receive Screen Layout)

**Purpose**: Assemble all widgets into the final ReceiveScreen layout

- [x] T033 Update ReceiveScreen layout with History button in AppBar in `lib/src/features/receive/presentation/receive_screen.dart`
- [x] T034 Add IdentityCard to center of ReceiveScreen
- [x] T035 Add ServerToggle below IdentityCard in ReceiveScreen
- [x] T036 Add QuickSaveSwitch below ServerToggle in ReceiveScreen
- [x] T037 Wire History button to navigate to `/receive/history` route
- [x] T038 Run `fvm flutter analyze` and fix any lint issues
- [ ] T039 Test complete flow per quickstart.md manual test scenarios

**Checkpoint**: All user stories integrated into final ReceiveScreen layout

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and edge case handling

- [x] T040 Handle network disconnection edge case - update IP address display reactively
- [x] T041 Verify toggle-during-transfer behavior (current transfer completes, no new accepted)
- [x] T042 Verify performance targets: <1s load (SC-001), <500ms toggle (SC-003)
- [x] T043 Run full quickstart.md validation for all test scenarios
- [x] T044 [P] Run `fvm flutter test` to verify no regressions in existing tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational
- **User Story 2 (Phase 4)**: Depends on Foundational (can run parallel to US1)
- **User Story 3 (Phase 5)**: Depends on Foundational (can run parallel to US1, US2)
- **User Story 4 (Phase 6)**: Depends on Foundational (can run parallel to US1, US2, US3)
- **Integration (Phase 7)**: Depends on ALL user stories being complete
- **Polish (Phase 8)**: Depends on Integration

### User Story Dependencies

| Story | Priority | Can Start After | Independent Test |
|-------|----------|-----------------|------------------|
| US1 - View Device Identity | P1 | Phase 2 (Foundational) | Identity Card displays avatar, alias, IP, port + copy works |
| US2 - Toggle Receive Mode | P1 | Phase 2 (Foundational) | Toggle → animation/status changes, server starts/stops |
| US3 - Toggle Quick Save | P2 | Phase 2 (Foundational) | Toggle → persist → relaunch → setting restored |
| US4 - View Transfer History | P2 | Phase 2 (Foundational) | History button → list with icons or empty state |

### Within Each User Story

- Widgets before integration
- Provider connections after widget creation
- Persistence after provider setup

### Parallel Opportunities

**Phase 2 (Foundational)**:
```
T006 [P] + T007 [P] → Run in parallel (different freezed models)
```

**Phase 3 (US1)**:
```
T014 [P] + T015 [P] → Run in parallel (different widget files)
```

**User Stories After Foundational**:
```
US1 + US2 + US3 + US4 → Can all start in parallel after Phase 2 completes
```

---

## Parallel Example: After Phase 2 Complete

```bash
# All user stories can be worked on in parallel by different developers:
Developer A: T014-T018 (US1 - Identity Card)
Developer B: T019-T024 (US2 - Receive Mode Toggle)  
Developer C: T025-T027 (US3 - Quick Save)
Developer D: T028-T032 (US4 - History View)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Identity Card)
4. Complete Phase 4: User Story 2 (Receive Mode Toggle)
5. **STOP and VALIDATE**: Test US1 + US2 independently
6. Partial integration possible (IdentityCard + ServerToggle in ReceiveScreen)

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Test Identity Card → Working identity display
3. Add US2 → Test Receive Mode → Working server control
4. Add US3 → Test Quick Save → Auto-accept preference
5. Add US4 → Test History → Complete receive tab
6. Integration → Full layout with all widgets
7. Polish → Edge cases and validation

### Suggested MVP Scope

**Minimum Viable Product**: User Stories 1 + 2 (both P1 priority)
- Users can see their device identity
- Users can toggle receive mode
- Core receive functionality complete

**Full Feature**: All 4 user stories
- Adds Quick Save convenience (P2)
- Adds History view (P2)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Existing infrastructure reused: ServerController, DeviceInfoProvider, HistoryRepository
- No new dependencies required - all features use existing packages
- All paths relative to repository root
- Commit after each task or logical group

