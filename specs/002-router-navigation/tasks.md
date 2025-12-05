# Tasks: Router and Navigation Structure (3 Tabs)

**Input**: Design documents from `/specs/002-router-navigation/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Widget tests explicitly requested in SC-004.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/core/`, `lib/src/features/`, `test/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create core routing infrastructure shared by all user stories

- [ ] T001 Create route constants in `lib/src/core/routing/routes.dart`
- [ ] T002 [P] Create feature folder structure for receive in `lib/src/features/receive/presentation/`
- [ ] T003 [P] Create feature folder structure for send in `lib/src/features/send/presentation/`
- [ ] T004 [P] Create feature folder structure for settings in `lib/src/features/settings/presentation/`
- [ ] T005 Create widgets folder in `lib/src/core/widgets/`

**Checkpoint**: Folder structure and route constants ready

---

## Phase 2: User Story 1 - Tab Navigation with State Preservation (Priority: P1) 🎯 MVP

**Goal**: Users can switch between Receive, Send, Settings tabs with state preserved

**Independent Test**: Launch app → navigate between tabs → verify correct content displays and state persists

### Widget Tests for User Story 1

- [ ] T006 [US1] Create widget test file `test/widget/navigation_test.dart` with test scaffolding
- [ ] T007 [US1] Add test: default route shows Receive tab in `test/widget/navigation_test.dart`
- [ ] T008 [US1] Add test: tapping Send tab shows Send screen in `test/widget/navigation_test.dart`
- [ ] T009 [US1] Add test: tapping Settings tab shows Settings screen in `test/widget/navigation_test.dart`

### Implementation for User Story 1

- [ ] T010 [P] [US1] Create ReceiveScreen placeholder in `lib/src/features/receive/presentation/receive_screen.dart`
- [ ] T011 [P] [US1] Create SendScreen placeholder in `lib/src/features/send/presentation/send_screen.dart`
- [ ] T012 [P] [US1] Create SettingsScreen placeholder in `lib/src/features/settings/presentation/settings_screen.dart`
- [ ] T013 [US1] Create ScaffoldWithNavBar with NavigationBar in `lib/src/core/widgets/scaffold_with_nav_bar.dart`
- [ ] T014 [US1] Create GoRouter with StatefulShellRoute.indexedStack in `lib/src/core/routing/app_router.dart`
- [ ] T015 [US1] Update app.dart to use MaterialApp.router with appRouter in `lib/app.dart`
- [ ] T016 [US1] Run `fvm flutter test` to verify widget tests pass
- [ ] T017 [US1] Run `fvm flutter run -d macos` to verify app launches with tab navigation

**Checkpoint**: Tab navigation working with state preservation - MVP complete

---

## Phase 3: User Story 2 - Responsive Navigation Layout (Priority: P2)

**Goal**: Navigation adapts between NavigationBar (<600px) and NavigationRail (≥600px)

**Independent Test**: Resize window across 600px threshold → verify layout switches smoothly

### Widget Tests for User Story 2

- [ ] T018 [US2] Add test: narrow screen shows NavigationBar in `test/widget/navigation_test.dart`
- [ ] T019 [US2] Add test: wide screen shows NavigationRail in `test/widget/navigation_test.dart`

### Implementation for User Story 2

- [ ] T020 [US2] Update ScaffoldWithNavBar with LayoutBuilder and 600px breakpoint in `lib/src/core/widgets/scaffold_with_nav_bar.dart`
- [ ] T021 [US2] Add NavigationRail layout for wide screens in `lib/src/core/widgets/scaffold_with_nav_bar.dart`
- [ ] T022 [US2] Run `fvm flutter test` to verify responsive tests pass
- [ ] T023 [US2] Manual test: resize window across 600px to verify smooth transition

**Checkpoint**: Responsive navigation working on all screen sizes

---

## Phase 4: User Story 3 - Deep Link Support (Priority: P3)

**Goal**: Direct navigation to `/receive`, `/send`, `/settings` with redirect for unknown paths

**Independent Test**: Navigate directly to URL paths → verify correct tab displays

### Widget Tests for User Story 3

- [ ] T024 [US3] Add test: navigating to /send path shows Send tab in `test/widget/navigation_test.dart`
- [ ] T025 [US3] Add test: unknown path redirects to /receive in `test/widget/navigation_test.dart`

### Implementation for User Story 3

- [ ] T026 [US3] Add redirect function for unknown paths in `lib/src/core/routing/app_router.dart`
- [ ] T027 [US3] Run `fvm flutter test` to verify deep link tests pass

**Checkpoint**: Deep linking and redirect working

---

## Phase 5: Polish & Validation

**Purpose**: Final quality checks and cross-cutting concerns

- [ ] T028 Run `fvm dart format .` to format all code
- [ ] T029 Run `fvm flutter analyze` to verify zero lint warnings
- [ ] T030 Run `fvm flutter test` to verify all tests pass
- [ ] T031 [P] Manual test on macOS: verify all 3 tabs work with responsive layout
- [ ] T032 Update `test/widget_test.dart` to remove outdated default test if needed

**Checkpoint**: Feature complete, all tests passing, zero lints

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - start immediately
- **Phase 2 (US1 MVP)**: Depends on Phase 1 completion
- **Phase 3 (US2)**: Depends on Phase 2 (US1) completion - builds on ScaffoldWithNavBar
- **Phase 4 (US3)**: Depends on Phase 2 (US1) completion - can run parallel with Phase 3
- **Phase 5 (Polish)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1 MVP)**: Core navigation - no dependencies on other stories
- **US2 (P2)**: Enhances ScaffoldWithNavBar from US1 - sequential after US1
- **US3 (P3)**: Adds redirect to router from US1 - can run parallel with US2

### Parallel Opportunities

**Within Phase 1**:
- T002, T003, T004 can run in parallel (different folders)

**Within Phase 2 (US1)**:
- T010, T011, T012 can run in parallel (different screen files)

**Between Phases 3 & 4**:
- US2 and US3 can run in parallel after US1 completes (different files)

---

## Parallel Example: User Story 1

```bash
# Launch all placeholder screens together:
T010: "Create ReceiveScreen placeholder in lib/src/features/receive/presentation/receive_screen.dart"
T011: "Create SendScreen placeholder in lib/src/features/send/presentation/send_screen.dart"
T012: "Create SettingsScreen placeholder in lib/src/features/settings/presentation/settings_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: User Story 1 (T006-T017)
3. **STOP and VALIDATE**: Tab navigation working with tests passing
4. Deploy/demo if ready - core navigation shell complete

### Incremental Delivery

1. Phase 1 + Phase 2 (US1) → MVP with basic tab navigation
2. Add Phase 3 (US2) → Responsive layout for all devices
3. Add Phase 4 (US3) → Deep link support
4. Phase 5 → Polish and final validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Widget tests written before implementation (TDD per SC-004)
- Commit after each phase checkpoint
- US2 and US3 can proceed in parallel after US1 completes
