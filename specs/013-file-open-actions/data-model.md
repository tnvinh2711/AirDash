# Data Model: File Open Actions

**Feature**: 013-file-open-actions | **Date**: 2025-12-08

## Overview

This feature adds a `savedPath` field to transfer history entries and introduces a new service for file operations.

---

## Domain Models

### TransferHistoryEntry (Updated)

```dart
/// Represents a stored transfer history entry (read from database).
class TransferHistoryEntry {
  const TransferHistoryEntry({
    required this.id,
    required this.transferId,
    required this.fileName,
    required this.fileCount,
    required this.totalSize,
    required this.fileType,
    required this.timestamp,
    required this.status,
    required this.direction,
    required this.remoteDeviceAlias,
    this.savedPath,  // NEW: nullable for backward compatibility
  });

  final int id;
  final String transferId;
  final String fileName;
  final int fileCount;
  final int totalSize;
  final String fileType;
  final DateTime timestamp;
  final TransferStatus status;
  final TransferDirection direction;
  final String remoteDeviceAlias;
  
  /// Absolute path where the received file was saved.
  /// 
  /// - `null` for sent transfers (direction == sent)
  /// - `null` for legacy entries created before this feature
  /// - Non-null for received transfers after this feature
  final String? savedPath;
  
  /// Whether this entry supports file open actions.
  /// 
  /// Returns true only if:
  /// - This is a received transfer
  /// - savedPath is not null
  bool get canOpenFile => 
      direction == TransferDirection.received && savedPath != null;
}
```

### NewTransferHistoryEntry (Updated)

```dart
/// Data required to create a new transfer history entry.
class NewTransferHistoryEntry {
  const NewTransferHistoryEntry({
    required this.transferId,
    required this.fileName,
    required this.fileCount,
    required this.totalSize,
    required this.fileType,
    required this.status,
    required this.direction,
    required this.remoteDeviceAlias,
    this.savedPath,  // NEW
  });

  final String transferId;
  final String fileName;
  final int fileCount;
  final int totalSize;
  final String fileType;
  final TransferStatus status;
  final TransferDirection direction;
  final String remoteDeviceAlias;
  final String? savedPath;  // NEW
}
```

---

## Database Schema

### TransferHistoryTable (Updated)

```dart
@DataClassName('TransferHistoryEntryData')
class TransferHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transferId => text()();
  TextColumn get fileName => text()();
  IntColumn get fileCount => integer().withDefault(const Constant(1))();
  IntColumn get totalSize => integer()();
  TextColumn get fileType => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get status => integer().map(const TransferStatusConverter())();
  IntColumn get direction => integer().map(const TransferDirectionConverter())();
  TextColumn get remoteDeviceAlias => text()();
  
  /// NEW: Absolute path where received file was saved.
  /// Nullable for backward compatibility with existing entries.
  TextColumn get savedPath => text().nullable()();
}
```

### Migration (v1 → v2)

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(
          transferHistoryTable, 
          transferHistoryTable.savedPath,
        );
      }
    },
  );
}
```

---

## New Service

### FileOpenService

```dart
/// Service for opening files and revealing them in file manager.
class FileOpenService {
  /// Opens a file with the system's default application.
  /// 
  /// Returns [FileOpenResult] indicating success or failure.
  Future<FileOpenResult> openFile(String filePath);
  
  /// Reveals a file in the system's file manager.
  /// 
  /// On desktop: Opens file manager with file selected.
  /// On mobile: Opens parent directory.
  Future<FileOpenResult> showInFolder(String filePath);
  
  /// Checks if a file exists at the given path.
  Future<bool> fileExists(String filePath);
}

/// Result of a file open operation.
enum FileOpenResult {
  success,
  fileNotFound,
  noAppAvailable,
  permissionDenied,
  unknownError,
}
```

---

## Entity Relationships

```
TransferHistoryEntry
├── id (PK)
├── transferId
├── fileName
├── fileCount
├── totalSize
├── fileType
├── timestamp
├── status (enum: completed, failed, cancelled)
├── direction (enum: sent, received)
├── remoteDeviceAlias
└── savedPath (nullable) ← NEW
```

## Validation Rules

| Field | Rule |
|-------|------|
| savedPath | Must be absolute path if non-null |
| savedPath | Only set for received transfers |
| savedPath | null for sent transfers |
| savedPath | null for legacy entries |

