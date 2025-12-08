# Tasks: README Update for Flux (AirDash)

**Input**: Design documents from `/specs/011-readme-update/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, quickstart.md ✅

**Tests**: Not required (documentation-only feature)

**Organization**: Tasks grouped by user story for independent implementation and validation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File path: `README.md` at repository root

---

## Phase 1: Setup

**Purpose**: Prepare for README update

- [x] T001 Review current README.md content at repository root
- [x] T002 [P] Review pubspec.yaml for version and SDK constraints
- [x] T003 [P] Review lib/src/features/ directory for feature modules list
- [x] T004 [P] Review constitution.md for technology stack details

**Checkpoint**: All source materials gathered

---

## Phase 2: User Story 1 - New Developer Onboarding (Priority: P1) 🎯 MVP

**Goal**: Enable developers to understand the project and run it within 15 minutes

**Independent Test**: Have someone unfamiliar with the project follow the README to build and run the app

### Implementation for User Story 1

- [x] T005 [US1] Add project title "Flux" and tagline in README.md
- [x] T006 [US1] Add badges (Flutter, Dart, License) in README.md
- [x] T007 [US1] Write Prerequisites section (FVM, Flutter 3.8+, Dart 3.0+) in README.md
- [x] T008 [US1] Write Getting Started section with clone/install/setup steps in README.md
- [x] T009 [US1] Write Running the App section with platform commands in README.md
- [x] T010 [US1] Write Running Tests section with test commands in README.md

**Checkpoint**: A developer can clone, setup, run app and tests following README

---

## Phase 3: User Story 2 - User Discovering the App (Priority: P2)

**Goal**: Help users understand what the app does and if it meets their needs

**Independent Test**: Show README to non-technical user and ask them to explain the app

### Implementation for User Story 2

- [x] T011 [US2] Write Overview section (2-3 sentences about local network file transfer) in README.md
- [x] T012 [US2] Write Features section with bullet list and emojis in README.md
- [x] T013 [US2] Add Supported Platforms table (Android, iOS, macOS, Windows, Linux) in README.md

**Checkpoint**: A user reading the top of README understands the app's value proposition

---

## Phase 4: User Story 3 - Contributor Understanding Architecture (Priority: P3)

**Goal**: Enable contributors to understand project structure and make meaningful contributions

**Independent Test**: Ask a developer to locate a specific feature based on README documentation

### Implementation for User Story 3

- [x] T014 [US3] Write Project Structure section with lib/src tree in README.md
- [x] T015 [US3] Write Technology Stack section with key libraries table in README.md
- [x] T016 [US3] Write Contributing section with guidelines in README.md
- [x] T017 [US3] Add License section referencing LICENSE file in README.md

**Checkpoint**: A contributor can understand architecture and how to contribute

---

## Phase 5: Polish & Validation

**Purpose**: Final review and validation against requirements

- [x] T018 Validate all 12 functional requirements are addressed in README.md
- [ ] T019 Verify markdown rendering on GitHub preview
- [ ] T020 Test 15-minute setup promise by following README instructions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - gather information first
- **US1 (Phase 2)**: Depends on Setup - creates core developer sections
- **US2 (Phase 3)**: Can run in parallel with US1 - creates user-facing sections
- **US3 (Phase 4)**: Can run in parallel with US1/US2 - creates contributor sections
- **Polish (Phase 5)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Setup complete → Developer onboarding sections
- **User Story 2 (P2)**: Setup complete → Can be written in parallel with US1
- **User Story 3 (P3)**: Setup complete → Can be written in parallel with US1/US2

### Within Single README File

Since all tasks modify README.md, execute sequentially within each story phase to avoid conflicts. However, different story phases can be written in parallel using separate sections.

---

## Parallel Opportunities

```text
# Phase 1 - All review tasks can run in parallel:
T002: Review pubspec.yaml
T003: Review lib/src/features/
T004: Review constitution.md

# Story content can be drafted in parallel (different sections):
US1: Prerequisites, Getting Started, Running sections
US2: Overview, Features, Platforms sections  
US3: Structure, Tech Stack, Contributing, License sections
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: User Story 1 (T005-T010)
3. **VALIDATE**: Test that a developer can follow instructions to run the app
4. If working, README is already useful for developers

### Incremental Delivery

1. US1 → Developers can onboard
2. US2 → Users understand the app's purpose  
3. US3 → Contributors can navigate codebase
4. Each story adds value independently

---

## Validation Checklist (from quickstart.md)

| FR | Description | Task |
|----|-------------|------|
| FR-001 | Title + description | T005 |
| FR-002 | Overview/purpose | T011 |
| FR-003 | Key features | T012 |
| FR-004 | Supported platforms | T013 |
| FR-005 | Prerequisites | T007 |
| FR-006 | Installation steps | T008 |
| FR-007 | Running instructions | T009 |
| FR-008 | Testing instructions | T010 |
| FR-009 | Project structure | T014 |
| FR-010 | Technology stack | T015 |
| FR-011 | Contribution guidelines | T016 |
| FR-012 | License info | T017 |

---

## Notes

- All tasks modify `README.md` at repository root
- Documentation-only feature - no code changes
- No test tasks required (manual validation)
- Total: 20 tasks across 5 phases

