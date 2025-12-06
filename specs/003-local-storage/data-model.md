# Data Model: Local Storage

**Feature**: 003-local-storage | **Date**: 2025-12-05

## Entity Definitions

### Setting

A key-value pair storing user preferences.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `key` | `String` | **Primary Key**, Not Null | Unique setting identifier (e.g., "theme", "alias", "port") |
| `value` | `String` | Not Null | Serialized setting value |

**Known Setting Keys**:
- `theme` - User's theme preference ("system", "light", "dark")
- `alias` - Device display name for transfers
- `port` - Network port for file transfer server

### TransferHistoryEntry

A record of a completed, failed, or cancelled file transfer.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | `int` | **Primary Key**, Auto-increment | Unique record identifier |
| `transferId` | `String` | Not Null | UUID identifying the transfer session |
| `fileName` | `String` | Not Null | Name of transferred file/folder |
| `fileCount` | `int` | Not Null, Default: 1 | Number of files (>1 for folders) |
| `totalSize` | `int` | Not Null | Total size in bytes |
| `fileType` | `String` | Not Null | File type identifier (e.g., "pdf", "image", "folder") |
| `timestamp` | `DateTime` | Not Null | When transfer completed/failed |
| `status` | `TransferStatus` | Not Null | Completion status |
| `direction` | `TransferDirection` | Not Null | Whether sent or received |
| `remoteDeviceAlias` | `String` | Not Null | Name of the other device |

## Enumerations

### TransferStatus

```dart
enum TransferStatus {
  completed,
  failed,
  cancelled,
}
```

### TransferDirection

```dart
enum TransferDirection {
  sent,
  received,
}
```

## Relationships

```
Setting (standalone)
  └── No relationships - simple key-value store

TransferHistoryEntry (standalone)
  └── No relationships - each entry is self-contained
```

## Validation Rules

### Setting
- `key`: Must be non-empty, alphanumeric with underscores allowed
- `value`: Must be non-empty string (empty values should use defaults)

### TransferHistoryEntry
- `transferId`: Must be valid UUID format
- `fileName`: Must be non-empty
- `fileCount`: Must be >= 1
- `totalSize`: Must be >= 0
- `timestamp`: Must be valid DateTime (not in future)

## State Transitions

### TransferHistoryEntry Status
```
[New Transfer Started]
        │
        ▼
   ┌─────────┐
   │ Pending │  (Not stored - in-memory only during transfer)
   └────┬────┘
        │
   ┌────┴────┬──────────┐
   ▼         ▼          ▼
┌─────────┐ ┌────────┐ ┌───────────┐
│Completed│ │ Failed │ │ Cancelled │
└─────────┘ └────────┘ └───────────┘
        │         │           │
        └─────────┴───────────┘
                  │
                  ▼
         [Written to DB]
```

**Note**: History entries are only written to the database once a transfer reaches a terminal state (Completed, Failed, or Cancelled). In-progress transfers are not persisted.

## Indexes

### TransferHistoryTable
- Primary Key: `id` (auto-indexed)
- Index on `timestamp` (for ordered queries)
- Optional: Index on `transferId` (for lookup by UUID)

### SettingsTable
- Primary Key: `key` (auto-indexed)

## Migration Path

**Version 1** (Initial):
- Create `settings_table` with key/value columns
- Create `transfer_history_table` with all specified columns

**Future Versions** (Planned):
- Version 2+: Add columns as features expand (e.g., `thumbnail_path`, `progress_percentage`)

