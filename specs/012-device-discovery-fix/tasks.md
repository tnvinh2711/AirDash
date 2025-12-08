# Tasks: Device Discovery Bug Fixes

**Input**: Design documents from `/specs/012-device-discovery-fix/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, quickstart.md ✓

**Tests**: Not explicitly requested - focusing on implementation only.

**Organization**: Tasks grouped by user story (US1: Reliable Device Discovery, US2: Responsive Refresh Button). Both stories are P1 priority but address different bugs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/features/discovery/application/discovery_controller.dart`
- **Tests**: `test/features/discovery/application/discovery_controller_test.dart`

---

## Phase 1: Setup

**Purpose**: Verify current state and prepare for changes

- [x] T001 Review existing `_cleanup()` method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T002 Review existing timer pattern (`_stalenessTimer`) in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T003 [P] Verify existing tests pass with `fvm flutter test test/features/discovery/`

---

## Phase 2: User Story 1 - Reliable Device Discovery (Priority: P1 🎯 MVP)

**Goal**: Devices remain visible for at least 2 minutes and survive temporary mDNS hiccups

**Independent Test**: Device B stays visible for 5+ minutes while broadcasting; disappears ~30s after stopping

### Implementation for User Story 1

- [x] T004 [US1] Add `_pendingRemovalTimers` map and `_removalGracePeriod` constant in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T005 [US1] Add `_scheduleDeviceRemoval()` method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T006 [US1] Add `_executeDeviceRemoval()` method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T007 [US1] Add `_cancelPendingRemoval()` method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T008 [US1] Modify `DeviceLostEvent` handler to call `_scheduleDeviceRemoval()` instead of `_removeDevice()` in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T009 [US1] Call `_cancelPendingRemoval()` in `_addOrUpdateDevice()` when device is re-discovered in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T010 [US1] Add cleanup for `_pendingRemovalTimers` in `_cleanup()` method in `lib/src/features/discovery/application/discovery_controller.dart`

**Checkpoint**: Device B survives mDNS hiccups and is removed only after 30-second grace period

---

## Phase 3: User Story 2 - Responsive Refresh Button (Priority: P1 🎯 MVP)

**Goal**: Refresh button returns to idle state within 10 seconds of being tapped

**Independent Test**: Tap refresh, loading appears for ~5s, then refresh icon returns

### Implementation for User Story 2

- [x] T011 [US2] Add `_scanTimeoutTimer` field and `_scanTimeout` constant in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T012 [US2] Add `_startScanTimeoutTimer()` helper method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T013 [US2] Add `_onScanTimeout()` callback that sets `isScanning = false` in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T014 [US2] Call `_startScanTimeoutTimer()` at end of `startScan()` method in `lib/src/features/discovery/application/discovery_controller.dart`
- [x] T015 [US2] Cancel `_scanTimeoutTimer` in `_cleanup()` method in `lib/src/features/discovery/application/discovery_controller.dart`

**Checkpoint**: Refresh button shows loading for ~5 seconds then returns to idle

---

## Phase 4: Polish & Verification

**Purpose**: Ensure all changes work together and pass existing tests

- [x] T016 Run existing tests with `fvm flutter test test/features/discovery/`
- [ ] T017 Manual verification: Open Send screen, tap refresh, verify loading stops after ~5s
- [ ] T018 Manual verification: Device B visible for 2+ minutes, disappears ~30s after stopping
- [x] T019 Update requirements checklist in `specs/012-device-discovery-fix/checklists/requirements.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - verify current state first
- **US1 (Phase 2)**: Depends on Setup - implements grace period
- **US2 (Phase 3)**: Depends on Setup - implements scan timeout
- **Polish (Phase 4)**: Depends on US1 and US2 completion

### User Story Dependencies

- **US1 and US2 are independent**: They modify different parts of the same file but don't conflict
- Both can be implemented in sequence (T004-T010, then T011-T015)
- Or by a single developer in one session (~30 min total)

### Parallel Opportunities

- T001, T002, T003 can all be done in parallel (review/verify only)
- US1 tasks (T004-T010) must be sequential (same file, same area)
- US2 tasks (T011-T015) must be sequential (same file, same area)
- US1 and US2 could be parallelized by different developers if needed

---

## Implementation Strategy

### MVP First

1. Complete Phase 1: Setup (verify baseline)
2. Complete Phase 2: US1 - Grace Period Fix (devices stay visible)
3. Complete Phase 3: US2 - Scan Timeout Fix (refresh button responsive)
4. Complete Phase 4: Polish (verify everything works)

### Single Developer Flow

Since both bugs are in the same file:

1. Review existing code (T001-T003)
2. Add all new fields at once (T004, T011)
3. Add grace period methods (T005-T007)
4. Add timeout methods (T012-T013)
5. Modify handlers (T008-T010, T014-T015)
6. Verify (T016-T019)

---

## Notes

- All implementation changes are in ONE file: `discovery_controller.dart`
- Follow existing timer pattern (`_stalenessTimer`) for consistency
- ~65 lines of code changes total
- Estimated time: 30 minutes

