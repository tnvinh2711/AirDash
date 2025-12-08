# Research: Send Tab UI

**Feature**: 008-send-ui | **Date**: 2025-12-06

## Research Tasks

### 1. How to persist selection list across app restarts?

**Decision**: Use `SettingsRepository` with JSON-serialized `List<SelectedItem>` stored as a single setting key.

**Rationale**:
- Consistent with existing settings persistence pattern (theme, alias, port)
- SelectedItem is already a Freezed class, easy to add JSON serialization
- No need for new database table - selection is transient data, not history
- Drift key-value store handles string values well

**Implementation Pattern**:
```dart
// Add to SettingKeys class
static const selectionQueue = 'selection_queue';

// Add to SettingsRepository
Future<List<SelectedItem>> getSelectionQueue() async {
  final json = await getSetting(SettingKeys.selectionQueue);
  if (json == null || json.isEmpty) return [];
  final list = jsonDecode(json) as List;
  return list.map((e) => SelectedItem.fromJson(e)).toList();
}

Future<void> setSelectionQueue(List<SelectedItem> items) async {
  final json = jsonEncode(items.map((e) => e.toJson()).toList());
  await setSetting(SettingKeys.selectionQueue, json);
}

// Add to SelectedItem (Freezed)
factory SelectedItem.fromJson(Map<String, dynamic> json) => _$SelectedItemFromJson(json);
Map<String, dynamic> toJson() => _$SelectedItemToJson(this);
```

**Alternatives Considered**:
- New Drift table: Overkill for transient selection data, adds migration complexity
- SharedPreferences directly: Less consistent with existing patterns

---

### 2. How to implement drag and drop on desktop?

**Decision**: Use `desktop_drop` package (already in pubspec.yaml from Feature 006 planning).

**Rationale**:
- Cross-platform support (macOS, Windows, Linux)
- Simple API: `DropTarget` widget wraps content area
- Returns list of file paths on drop
- Works well with existing `FilePickerService` patterns

**Implementation Pattern**:
```dart
DropTarget(
  onDragDone: (detail) {
    final paths = detail.files.map((f) => f.path).toList();
    ref.read(fileSelectionControllerProvider.notifier).addPaths(paths);
  },
  onDragEntered: (_) => setState(() => _isDragging = true),
  onDragExited: (_) => setState(() => _isDragging = false),
  child: Stack(
    children: [
      // Main content
      if (_isDragging) DropZoneOverlay(),
    ],
  ),
)
```

**Alternatives Considered**:
- `super_drag_and_drop`: More complex API, overkill for file drops
- Platform channels: Unnecessary when package exists

---

### 3. How to implement responsive device grid?

**Decision**: Use `GridView.builder` with `SliverGridDelegateWithMaxCrossAxisExtent`.

**Rationale**:
- Automatically adjusts column count based on available width
- Consistent item sizing across screen sizes
- Built-in Flutter widget, no dependencies
- `maxCrossAxisExtent: 180` gives 2-3 cols on mobile, 3-4+ on desktop

**Implementation Pattern**:
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 180,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.9, // Slightly taller than wide
  ),
  itemCount: devices.length,
  itemBuilder: (context, index) => DeviceGridItem(device: devices[index]),
)
```

---

### 4. How to handle media picker (photos/videos)?

**Decision**: Use `file_picker` with `FileType.media` filter.

**Rationale**:
- Already using `file_picker` for files/folders
- Supports `FileType.media` for photos and videos
- Cross-platform (uses system gallery picker on mobile)
- Consistent API with existing `FilePickerService`

**Implementation Pattern**:
```dart
// Add to FilePickerService
Future<List<SelectedItem>> pickMedia() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.media,
    allowMultiple: true,
  );
  if (result == null) return [];
  return result.files
      .where((f) => f.path != null)
      .map((f) => _fileToSelectedItem(f, SelectedItemType.media))
      .toList();
}
```

**Note**: On iOS/Android, this opens the photo gallery. On desktop, opens file picker filtered to media types.

---

## Dependencies Summary

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `file_picker` | ^8.0.0 | File/folder/media selection | ✅ Existing |
| `desktop_drop` | ^0.5.0 | Desktop drag and drop | ✅ Add to pubspec |
| `freezed_annotation` | ^2.4.0 | JSON serialization | ✅ Existing |
| `json_annotation` | ^4.8.0 | JSON codegen | ✅ Existing |

## Integration Points

| Component | Location | Usage |
|-----------|----------|-------|
| `FileSelectionController` | `send/application/` | Add/remove selection items, persistence |
| `DiscoveryController` | `discovery/application/` | Watch devices, call `refresh()` |
| `TransferController` | `send/application/` | Initiate transfer on device tap |
| `SettingsRepository` | `settings/data/` | Persist selection queue |
| `Device` | `discovery/domain/` | Device model for grid items |

