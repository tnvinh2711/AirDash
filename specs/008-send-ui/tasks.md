# Tasks: Send Tab UI

**Input**: Design documents from `/specs/008-send-ui/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Add dependencies and prepare project for Send UI implementation

- [x] T001 Add `desktop_drop` package via `fvm flutter pub add desktop_drop`
- [x] T002 Run `fvm flutter pub get` to update dependencies

---

## Phase 2: Foundational (Domain & Data Layer)

**Purpose**: Core infrastructure that MUST be complete before user story UI work

**⚠️ CRITICAL**: All user stories depend on these tasks completing first

- [x] T003 [P] Add `media` value to `SelectedItemType` enum in `lib/src/features/send/domain/selected_item_type.dart`
- [x] T004 [P] Add JSON serialization to `SelectedItem` (add `@JsonSerializable()`, `fromJson`, `toJson`) in `lib/src/features/send/domain/selected_item.dart`
- [x] T005 [P] Add `SettingKeys.selectionQueue` constant to `lib/src/features/settings/data/settings_repository.dart`
- [x] T006 Add `getSelectionQueue()` and `setSelectionQueue()` methods to `SettingsRepository` in `lib/src/features/settings/data/settings_repository.dart`
- [x] T007 Add `pickMedia()` method to `FilePickerService` in `lib/src/features/send/data/file_picker_service.dart`
- [x] T008 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to regenerate freezed/json files
- [x] T009 Update `FileSelectionController.build()` to load persisted selection from `SettingsRepository` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T010 Add persistence save after each state mutation (pickFiles, pickFolder, pasteText, removeItem, clear) in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T011 Add `pickMedia()` method to `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T012 Add `addPaths(List<String>)` method for drag-drop in `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T013 Add `showSizeWarning` getter (> 1GB threshold) to `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T014 Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to regenerate provider files

**Checkpoint**: Foundation ready - all domain/data/application layer complete

---

## Phase 3: User Story 1 - Select Files to Send (Priority: P1) 🎯 MVP

**Goal**: Users can select files, folders, text, or media to add to the selection queue

**Independent Test**: Tap File/Folder/Text/Media buttons → items appear in selection list with name and size

- [x] T015 [P] [US1] Create `SelectionActionButtons` widget with File, Folder, Text, Media buttons in `lib/src/features/send/presentation/widgets/selection_action_buttons.dart`
- [x] T016 [P] [US1] Create `SelectionItemTile` widget showing type icon, name, size, X button in `lib/src/features/send/presentation/widgets/selection_item_tile.dart`
- [x] T017 [US1] Create `SelectionList` widget with ListView of `SelectionItemTile` items in `lib/src/features/send/presentation/widgets/selection_list.dart`
- [x] T018 [US1] Add empty state to `SelectionList` when no items selected in `lib/src/features/send/presentation/widgets/selection_list.dart`
- [x] T019 [US1] Add size warning banner to `SelectionList` when total > 1GB in `lib/src/features/send/presentation/widgets/selection_list.dart`
- [x] T020 [US1] Update `SendScreen` to show Selection section with `SelectionActionButtons` and `SelectionList` in `lib/src/features/send/presentation/send_screen.dart`

**Checkpoint**: US1 complete - users can add files/folders/text/media to selection

---

## Phase 4: User Story 2 - Manage Selection List (Priority: P1)

**Goal**: Users can view and remove items from selection list

**Independent Test**: Add multiple items → tap X on one → item removed, others remain

- [x] T021 [US2] Wire X button in `SelectionItemTile` to call `removeItem(id)` in `lib/src/features/send/presentation/widgets/selection_item_tile.dart`
- [x] T022 [US2] Ensure selection list updates reactively when items removed in `lib/src/features/send/presentation/widgets/selection_list.dart`

**Checkpoint**: US2 complete - users can manage their selection

---

## Phase 5: User Story 3 - Drag and Drop Files (Priority: P2)

**Goal**: Desktop users can drag files directly onto the app window

**Independent Test**: Drag file from file manager onto app → file appears in selection list

- [x] T023 [P] [US3] Create `DropZoneOverlay` widget with visual feedback in `lib/src/features/send/presentation/widgets/drop_zone_overlay.dart`
- [x] T024 [US3] Wrap `SendScreen` in `DropTarget` from `desktop_drop` package in `lib/src/features/send/presentation/send_screen.dart`
- [x] T025 [US3] Handle drop events to call `FileSelectionController.addPaths()` in `lib/src/features/send/presentation/send_screen.dart`
- [x] T026 [US3] Show/hide `DropZoneOverlay` based on drag state in `lib/src/features/send/presentation/send_screen.dart`

**Checkpoint**: US3 complete - desktop drag-drop works

---

## Phase 6: User Story 4 - View Nearby Devices (Priority: P1)

**Goal**: Users can see discovered devices in a responsive grid

**Independent Test**: Start app with other AirDash devices on LAN → devices appear in grid with OS icon, alias, IP

- [x] T027 [P] [US4] Create `DeviceGridItem` widget showing OS icon, alias, IP in `lib/src/features/send/presentation/widgets/device_grid_item.dart`
- [x] T028 [US4] Create `DeviceGrid` widget with responsive GridView (2-3 cols mobile, 3-4 desktop) in `lib/src/features/send/presentation/widgets/device_grid.dart`
- [x] T029 [US4] Add "Nearby Devices" header to `DeviceGrid` in `lib/src/features/send/presentation/widgets/device_grid.dart`
- [x] T030 [US4] Add empty state to `DeviceGrid` when no devices found in `lib/src/features/send/presentation/widgets/device_grid.dart`
- [x] T031 [US4] Add loading indicator to `DeviceGrid` when scanning in progress in `lib/src/features/send/presentation/widgets/device_grid.dart`
- [x] T032 [US4] Update `SendScreen` to show Devices section with `DeviceGrid` below Selection in `lib/src/features/send/presentation/send_screen.dart`
- [x] T033 [US4] Start discovery scan in `SendScreen` initState/build in `lib/src/features/send/presentation/send_screen.dart`

**Checkpoint**: US4 complete - nearby devices visible

---

## Phase 7: User Story 5 - Refresh Device Discovery (Priority: P2)

**Goal**: Users can manually refresh the device list

**Independent Test**: Tap refresh button → loading indicator appears → device list updates

- [x] T034 [US5] Add Refresh icon button to `DeviceGrid` header in `lib/src/features/send/presentation/widgets/device_grid.dart`
- [x] T035 [US5] Wire Refresh button to call `DiscoveryController.refresh()` in `lib/src/features/send/presentation/widgets/device_grid.dart`

**Checkpoint**: US5 complete - manual refresh works

---

## Phase 8: User Story 6 - Initiate File Transfer (Priority: P1)

**Goal**: Users can tap a device to start sending selected items

**Independent Test**: Select file → tap device → transfer starts (integrates with feature 006)

- [x] T036 [US6] Add onTap handler to `DeviceGridItem` to initiate transfer in `lib/src/features/send/presentation/widgets/device_grid_item.dart`
- [x] T037 [US6] Disable `DeviceGridItem` (greyed, not tappable) when selection is empty in `lib/src/features/send/presentation/widgets/device_grid_item.dart`
- [x] T038 [US6] Implement onTap to call `TransferController.sendAll(items, device)` in `lib/src/features/send/presentation/send_screen.dart`
- [x] T039 [US6] Clear selection after successful transfer in `lib/src/features/send/presentation/send_screen.dart`

**Checkpoint**: US6 complete - full send flow works end-to-end

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and edge case handling

- [x] T040 Add duplicate prevention check in `FileSelectionController.pickFiles/pickFolder/addPaths` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T041 Add file existence validation before transfer in `FileSelectionController` in `lib/src/features/send/application/file_selection_controller.dart`
- [x] T042 Verify accessibility (tappable areas, contrast) across all widgets
- [x] T043 Run `fvm flutter analyze` and fix any lints
- [x] T044 Run `fvm flutter test` and ensure all existing tests pass
- [x] T045 Run verification checklist from quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phases 3-8)**: All depend on Foundational completion
  - US1 (Select) + US2 (Manage) → can proceed in parallel
  - US3 (Drag-Drop) → depends on US1 (needs selection working)
  - US4 (View Devices) → can proceed in parallel with US1-3
  - US5 (Refresh) → depends on US4 (needs device grid)
  - US6 (Transfer) → depends on US1, US2, US4 (needs selection + devices)
- **Polish (Phase 9)**: Depends on all user stories complete

### Parallel Opportunities

**Phase 2 Parallel Group**:
- T003, T004, T005 (different files, no dependencies)

**Phase 3 Parallel Group**:
- T015, T016 (different widget files)

**Phase 5 + Phase 6 can run in parallel** (different widget groups)

---

## Parallel Example: Foundational Phase

```bash
# Launch in parallel (different files):
T003: "Add media to SelectedItemType in selected_item_type.dart"
T004: "Add JSON serialization to SelectedItem in selected_item.dart"
T005: "Add selectionQueue key to SettingsRepository in settings_repository.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2, 4, 6)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T014)
3. Complete Phase 3: US1 - Select Files (T015-T020)
4. Complete Phase 4: US2 - Manage Selection (T021-T022)
5. Complete Phase 6: US4 - View Devices (T027-T033)
6. Complete Phase 8: US6 - Initiate Transfer (T036-T039)
7. **STOP and VALIDATE**: Full send flow works end-to-end

### Incremental Delivery

1. Setup + Foundational → Domain/data ready
2. US1 + US2 → Selection fully functional (can demo!)
3. US4 → Device discovery visible (can demo!)
4. US6 → Transfer works (MVP complete!)
5. US3 → Drag-drop enhancement (desktop users happy)
6. US5 → Refresh button (nice-to-have)
7. Polish → Production ready

---

## Summary

| Phase | Tasks | Parallel Tasks | Story |
|-------|-------|----------------|-------|
| Setup | 2 | 0 | - |
| Foundational | 12 | 3 | - |
| US1 (Select) | 6 | 2 | P1 |
| US2 (Manage) | 2 | 0 | P1 |
| US3 (Drag-Drop) | 4 | 1 | P2 |
| US4 (Devices) | 7 | 1 | P1 |
| US5 (Refresh) | 2 | 0 | P2 |
| US6 (Transfer) | 4 | 0 | P1 |
| Polish | 6 | 0 | - |
| **Total** | **45** | **7** | - |

---

## Notes

- All paths relative to repository root
- Run `build_runner` after domain changes (T008, T014)
- Test on both mobile (iOS/Android) and desktop (macOS/Windows/Linux)
- Commit after each phase or logical task group
