# Tasks: Project Initialization with FVM and Folder Structure

**Input**: Design documents from `/specs/001-project-init/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Tests**: Not included - infrastructure setup feature, no application logic to test.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/src/core/`, `lib/src/features/`, `test/` at repository root
- FVM configuration: `.fvm/` at repository root
- Analysis options: `analysis_options.yaml` at repository root

---

## Phase 1: User Story 1 - Initialize Flutter Project with FVM (Priority: P1) 🎯 MVP

**Goal**: Create a new Flutter project managed by FVM with stable channel configuration

**Independent Test**: `fvm flutter doctor` runs successfully and `fvm flutter --version` shows stable version

### Implementation for User Story 1

- [x] T001 [US1] Install Flutter stable channel via FVM: `fvm install stable`
- [x] T002 [US1] Configure project to use stable channel: `fvm use stable`
- [x] T003 [US1] Create Flutter project with all platforms: `fvm flutter create --platforms=android,ios,macos,windows,linux --org=com.flux .`
- [x] T004 [US1] Verify `.fvm/fvm_config.json` exists and contains stable channel reference
- [x] T005 [US1] Add `.fvm/flutter_sdk` to `.gitignore` (SDK symlink should not be committed)
- [x] T006 [US1] Verify `fvm flutter doctor` executes without errors

**Checkpoint**: FVM configured, Flutter project created with all 5 platforms enabled

---

## Phase 2: User Story 2 - Install Core Dependencies (Priority: P2)

**Goal**: Install all constitution-mandated dependencies for state management, routing, theming, and code generation

**Independent Test**: `fvm flutter pub get` succeeds and `pubspec.yaml` contains all required packages

### Implementation for User Story 2

- [x] T007 [US2] Add runtime dependencies to pubspec.yaml: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `flex_color_scheme`, `freezed_annotation`
- [x] T008 [US2] Add dev dependencies to pubspec.yaml: `riverpod_generator`, `freezed`, `build_runner`, `very_good_analysis`
- [x] T009 [US2] Run `fvm flutter pub get` to resolve all dependencies
- [x] T010 [US2] Verify no dependency conflicts in pubspec.lock

**Checkpoint**: All dependencies installed, `fvm flutter pub get` succeeds

---

## Phase 3: User Story 3 - Create Standard Folder Structure (Priority: P3)

**Goal**: Establish constitution-compliant Riverpod Architecture folder structure

**Independent Test**: All required directories exist under `lib/src/`

### Implementation for User Story 3

- [x] T011 [P] [US3] Create `lib/src/core/` directory with `.gitkeep` placeholder
- [x] T012 [P] [US3] Create `lib/src/features/` directory with `.gitkeep` placeholder
- [x] T013 [US3] Create `lib/app.dart` with root widget placeholder (Material3 + FlexColorScheme ready)
- [x] T014 [US3] Update `lib/main.dart` to use `lib/app.dart` as entry point
- [x] T015 [US3] Remove default Flutter counter app code from `lib/main.dart`

**Checkpoint**: Folder structure matches constitution layout, app runs with placeholder

---

## Phase 4: User Story 4 - Configure Strict Linting Rules (Priority: P4)

**Goal**: Configure Very Good Analysis for strict code quality enforcement

**Independent Test**: `fvm flutter analyze` runs with strict rules and returns zero warnings

### Implementation for User Story 4

- [x] T016 [US4] Create `analysis_options.yaml` with Very Good Analysis include
- [x] T017 [US4] Run `dart format .` to format all Dart files
- [x] T018 [US4] Run `fvm flutter analyze` and fix any warnings in generated code
- [x] T019 [US4] Verify zero warnings from `fvm flutter analyze`

**Checkpoint**: Linting configured, all code passes analysis

---

## Phase 5: Final Validation & Platform Testing

**Goal**: Verify the app builds and runs on all 5 target platforms

### Platform Validation

- [x] T020 [P] Run `fvm flutter run -d macos` and verify app launches
- [ ] T021 [P] Run `fvm flutter run -d windows` and verify app launches (Windows only) - SKIPPED: Requires Windows
- [ ] T022 [P] Run `fvm flutter run -d linux` and verify app launches (Linux only) - SKIPPED: Requires Linux
- [ ] T023 [P] Run `fvm flutter run -d android` and verify app launches on emulator/device - SKIPPED: No emulator available
- [ ] T024 [P] Run `fvm flutter run -d ios` and verify app launches on simulator/device (macOS only) - SKIPPED: No simulator available
- [x] T025 Run `fvm flutter test` to verify default test passes

**Checkpoint**: All 5 platforms validated, project ready for feature development

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1)**: No dependencies - FVM/Flutter must exist first
- **Phase 2 (US2)**: Depends on Phase 1 - project must exist for pubspec.yaml
- **Phase 3 (US3)**: Depends on Phase 2 - dependencies needed for app.dart imports
- **Phase 4 (US4)**: Depends on Phase 3 - code must exist to analyze
- **Phase 5 (Validation)**: Depends on all previous phases

### User Story Dependencies

```
US1 (FVM + Project) → US2 (Dependencies) → US3 (Folders) → US4 (Linting) → Validation
```

**Note**: This feature is sequential by nature - each story builds on the previous.

### Parallel Opportunities

- T011, T012: Folder creation can run in parallel
- T020-T024: Platform validation can run in parallel (on different machines)

---

## Parallel Example: Platform Validation (Phase 5)

```bash
# On macOS machine:
fvm flutter run -d macos  # T020
fvm flutter run -d ios    # T024

# On Windows machine:
fvm flutter run -d windows  # T021
fvm flutter run -d android  # T023

# On Linux machine:
fvm flutter run -d linux  # T022
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: FVM + Flutter project
2. **STOP and VALIDATE**: `fvm flutter doctor` passes
3. Project is runnable (default counter app)

### Incremental Delivery

1. Phase 1 → Project exists and runs
2. Phase 2 → Dependencies ready for feature development
3. Phase 3 → Folder structure ready for features
4. Phase 4 → Code quality enforced
5. Phase 5 → All platforms validated

---

## Notes

- All tasks use `fvm flutter` prefix for SDK consistency
- Commit after each phase completion
- Platform validation (Phase 5) may require specific OS access
- Dependencies versions should follow latest stable at time of creation

