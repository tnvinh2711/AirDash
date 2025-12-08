# Quickstart: Send Tab UI

**Feature**: 008-send-ui | **Date**: 2025-12-06

## Prerequisites

- Feature 004 (Discovery) implemented and working
- Feature 006 (File Transfer Client) implemented and working
- `desktop_drop` package added to pubspec.yaml:
  ```bash
  fvm flutter pub add desktop_drop
  ```

## Implementation Order

### Phase 1: Domain & Data Layer (Estimated: 1 hour)

1. **Update `SelectedItemType`** - Add `media` enum value
   - File: `lib/src/features/send/domain/selected_item_type.dart`

2. **Update `SelectedItem`** - Add JSON serialization
   - File: `lib/src/features/send/domain/selected_item.dart`
   - Add `@JsonSerializable()` annotation
   - Add `fromJson` factory and `toJson` method
   - Run `build_runner` to generate

3. **Update `SettingsRepository`** - Add selection persistence
   - File: `lib/src/features/settings/data/settings_repository.dart`
   - Add `SettingKeys.selectionQueue` constant
   - Add `getSelectionQueue()` and `setSelectionQueue()` methods

4. **Update `FilePickerService`** - Add media picker
   - File: `lib/src/features/send/data/file_picker_service.dart`
   - Add `pickMedia()` method using `FileType.media`

### Phase 2: Application Layer (Estimated: 1.5 hours)

1. **Update `FileSelectionController`** - Add persistence and media
   - File: `lib/src/features/send/application/file_selection_controller.dart`
   - Load from `SettingsRepository` in `build()`
   - Save to `SettingsRepository` after each state change
   - Add `pickMedia()` method
   - Add `addPaths(List<String>)` for drag-drop
   - Add `bool get showSizeWarning` (> 1GB)

### Phase 3: Presentation Layer (Estimated: 3 hours)

1. **Create `SelectionActionButtons`** widget
   - File: `lib/src/features/send/presentation/widgets/selection_action_buttons.dart`
   - Four buttons: File, Folder, Text, Media
   - Each calls corresponding controller method

2. **Create `SelectionItemTile`** widget
   - File: `lib/src/features/send/presentation/widgets/selection_item_tile.dart`
   - Shows: type icon, name, size, X button
   - X button calls `removeItem(id)`

3. **Create `SelectionList`** widget
   - File: `lib/src/features/send/presentation/widgets/selection_list.dart`
   - ListView of `SelectionItemTile` widgets
   - Empty state when no items
   - Size warning banner when > 1GB

4. **Create `DeviceGridItem`** widget
   - File: `lib/src/features/send/presentation/widgets/device_grid_item.dart`
   - Shows: OS icon, alias, IP
   - Tappable when selection not empty
   - Disabled (greyed) when selection empty

5. **Create `DeviceGrid`** widget
   - File: `lib/src/features/send/presentation/widgets/device_grid.dart`
   - GridView with responsive columns
   - Header: "Nearby Devices" + Refresh button
   - Empty state when no devices
   - Loading indicator when scanning

6. **Create `DropZoneOverlay`** widget (desktop only)
   - File: `lib/src/features/send/presentation/widgets/drop_zone_overlay.dart`
   - Semi-transparent overlay with drop icon
   - Shows when dragging files over

7. **Update `SendScreen`**
   - File: `lib/src/features/send/presentation/send_screen.dart`
   - Layout: Selection section (top) + Devices section (bottom)
   - Wrap in `DropTarget` for desktop
   - Start discovery scan on init

### Phase 4: Tests (Estimated: 2 hours)

1. **Unit tests for persistence**
   - Test `getSelectionQueue()` / `setSelectionQueue()`
   - Test JSON serialization round-trip

2. **Unit tests for `FileSelectionController`**
   - Test persistence on add/remove
   - Test size warning threshold
   - Test duplicate prevention

3. **Widget tests for `SelectionList`**
   - Test empty state
   - Test item display
   - Test remove button

4. **Widget tests for `DeviceGrid`**
   - Test empty state
   - Test device display
   - Test disabled state when selection empty

## Key Integration Points

### Starting Discovery Scan

```dart
// In SendScreen initState or build
ref.read(discoveryControllerProvider.notifier).startScan();
```

### Refreshing Devices

```dart
// On refresh button tap
ref.read(discoveryControllerProvider.notifier).refresh();
```

### Initiating Transfer

```dart
// On device tap (when selection not empty)
final items = ref.read(fileSelectionControllerProvider);
final controller = ref.read(transferControllerProvider.notifier);
await controller.sendAll(items, device);
// Clear selection after successful send
ref.read(fileSelectionControllerProvider.notifier).clear();
```

## Verification Checklist

- [ ] File/Folder/Text/Media buttons work on all platforms
- [ ] Selection persists after app restart
- [ ] Drag-drop works on macOS/Windows/Linux
- [ ] Device grid shows 2-3 columns on mobile, 3-4 on desktop
- [ ] Devices are disabled when selection is empty
- [ ] Refresh button restarts discovery scan
- [ ] Size warning appears at 1GB threshold
- [ ] Transfer initiates on device tap
- [ ] All tests pass with `fvm flutter test`

