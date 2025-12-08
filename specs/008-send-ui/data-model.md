# Data Model: Send Tab UI

**Feature**: 008-send-ui | **Date**: 2025-12-06

## Entities

### SelectedItem (EXISTING - MODIFY)

**Location**: `lib/src/features/send/domain/selected_item.dart`

**Changes**: Add JSON serialization for persistence.

```dart
@freezed
class SelectedItem with _$SelectedItem {
  const factory SelectedItem({
    required String id,
    required SelectedItemType type,
    String? path,
    String? content,
    required String displayName,
    required int sizeEstimate,
  }) = _SelectedItem;

  const SelectedItem._();

  // ADD: JSON serialization
  factory SelectedItem.fromJson(Map<String, dynamic> json) => 
      _$SelectedItemFromJson(json);
}
```

**Validation Rules**:
- `id`: Required, non-empty UUID
- `type`: Required enum value
- `path`: Required for file/folder/media types
- `content`: Required for text type
- `displayName`: Required, non-empty
- `sizeEstimate`: Required, >= 0

---

### SelectedItemType (EXISTING - MODIFY)

**Location**: `lib/src/features/send/domain/selected_item_type.dart`

**Changes**: Add `media` type.

```dart
enum SelectedItemType {
  file,
  folder,
  text,
  media,  // ADD: for photos/videos
}
```

---

### Device (EXISTING - NO CHANGES)

**Location**: `lib/src/features/discovery/domain/device.dart`

Used as-is for displaying devices in the grid.

```dart
@freezed
class Device with _$Device {
  const factory Device({
    required String serviceInstanceName,
    required String ip,
    required int port,
    required String alias,
    required DeviceType deviceType,
    required String os,
    required DateTime lastSeen,
  }) = _Device;
}
```

---

## State Models

### FileSelectionController State

**Type**: `List<SelectedItem>`

**Persistence**: JSON-serialized to `SettingsRepository` key `selection_queue`

**State Transitions**:
- `[]` (empty) → `[item]` (pickFiles/pickFolder/pickMedia/pasteText)
- `[items]` → `[items - removed]` (removeItem)
- `[items]` → `[]` (clear, or after successful transfer)

---

### DiscoveryState (EXISTING - NO CHANGES)

**Location**: `lib/src/features/discovery/domain/discovery_state.dart`

Used to watch `devices` list and `isScanning` status.

---

## Persistence Schema

### Settings Table (EXISTING)

**Key**: `selection_queue`
**Value**: JSON string

```json
[
  {
    "id": "uuid-1",
    "type": "file",
    "path": "/path/to/file.pdf",
    "displayName": "file.pdf",
    "sizeEstimate": 1024000
  },
  {
    "id": "uuid-2", 
    "type": "text",
    "content": "Hello world",
    "displayName": "Pasted Text - 2025-12-06 10:30:00.txt",
    "sizeEstimate": 11
  }
]
```

---

## UI State

### SendScreen Local State

```dart
class _SendScreenState {
  bool isDragging = false;  // Desktop drop zone highlight
}
```

### Computed Properties

```dart
// From FileSelectionController
bool get isEmpty => state.isEmpty;
int get count => state.length;
int get totalSize => state.fold(0, (sum, item) => sum + item.sizeEstimate);
bool get showSizeWarning => totalSize > 1024 * 1024 * 1024; // 1GB

// From DiscoveryController
bool get isScanning => state.valueOrNull?.isScanning ?? false;
List<Device> get devices => state.valueOrNull?.devices ?? [];
bool get hasDevices => devices.isNotEmpty;
```

---

## Relationships

```
FileSelectionController (state: List<SelectedItem>)
    ├── persists to → SettingsRepository.selectionQueue
    └── provides items to → TransferController.sendAll()

DiscoveryController (state: DiscoveryState)
    └── provides devices to → DeviceGrid UI

TransferController
    ├── receives items from → FileSelectionController
    └── receives target from → DeviceGrid tap
```

