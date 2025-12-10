# Quickstart: File Open Actions

**Feature**: 013-file-open-actions | **Date**: 2025-12-08

## Prerequisites

- Flutter SDK via FVM (stable channel)
- Existing project with drift, flutter_riverpod, freezed
- Completed features: 003-local-storage, 007-receive-ui

## 1. Add Dependencies

```bash
flutter pub add open_filex
```

## 2. Update Database Schema

### 2.1 Add savedPath column to table

Edit `lib/src/core/database/tables/transfer_history_table.dart`:
```dart
// Add after remoteDeviceAlias column:
TextColumn get savedPath => text().nullable()();
```

### 2.2 Update schema version and migration

Edit `lib/src/core/database/app_database.dart`:
```dart
@override
int get schemaVersion => 2;  // Was 1

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

### 2.3 Regenerate database code

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 3. Update Domain Models

### 3.1 Update TransferHistoryEntry

Edit `lib/src/features/history/domain/transfer_history_entry.dart`:
```dart
class TransferHistoryEntry {
  const TransferHistoryEntry({
    // ... existing fields ...
    this.savedPath,
  });
  
  // ... existing fields ...
  
  final String? savedPath;
  
  bool get canOpenFile => 
      direction == TransferDirection.received && savedPath != null;
}
```

### 3.2 Update NewTransferHistoryEntry

Edit `lib/src/features/history/domain/new_transfer_history_entry.dart`:
```dart
class NewTransferHistoryEntry {
  const NewTransferHistoryEntry({
    // ... existing fields ...
    this.savedPath,
  });
  
  // ... existing fields ...
  
  final String? savedPath;
}
```

## 4. Create FileOpenService

Create `lib/src/core/services/file_open_service.dart`:
```dart
import 'dart:io';
import 'package:open_filex/open_filex.dart';

enum FileOpenResult { success, fileNotFound, noAppAvailable, permissionDenied, unknownError }

class FileOpenService {
  Future<FileOpenResult> openFile(String filePath) async {
    if (!await File(filePath).exists()) return FileOpenResult.fileNotFound;
    final result = await OpenFilex.open(filePath);
    return _mapResult(result.type);
  }
  
  Future<FileOpenResult> showInFolder(String filePath) async {
    if (!await File(filePath).exists()) return FileOpenResult.fileNotFound;
    // Platform-specific implementation
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', filePath]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [File(filePath).parent.path]);
    } else {
      await OpenFilex.open(File(filePath).parent.path);
    }
    return FileOpenResult.success;
  }
  
  Future<bool> fileExists(String filePath) => File(filePath).exists();
  
  FileOpenResult _mapResult(ResultType type) {
    switch (type) {
      case ResultType.done: return FileOpenResult.success;
      case ResultType.fileNotFound: return FileOpenResult.fileNotFound;
      case ResultType.noAppToOpen: return FileOpenResult.noAppAvailable;
      case ResultType.permissionDenied: return FileOpenResult.permissionDenied;
      case ResultType.error: return FileOpenResult.unknownError;
    }
  }
}
```

## 5. Create Completion Dialog

Create `lib/src/features/receive/presentation/widgets/transfer_complete_dialog.dart`:
```dart
class TransferCompleteDialog extends StatelessWidget {
  const TransferCompleteDialog({super.key, required this.transfer});
  
  final CompletedTransferInfo transfer;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Complete'),
      content: Text('Received: ${transfer.fileName}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () => _showInFolder(context),
          child: const Text('Show in Folder'),
        ),
        FilledButton(
          onPressed: () => _openFile(context),
          child: const Text('Open'),
        ),
      ],
    );
  }
}
```

## 6. Update History Repository

Edit `lib/src/features/history/data/history_repository.dart`:
```dart
// In addEntry method:
final companion = TransferHistoryTableCompanion.insert(
  // ... existing fields ...
  savedPath: Value(entry.savedPath),  // Add this
);

// In _mapToEntry method:
return TransferHistoryEntry(
  // ... existing fields ...
  savedPath: row.savedPath,  // Add this
);
```

## 7. Verification Checklist

- [ ] `flutter pub get` succeeds
- [ ] `dart run build_runner build` succeeds
- [ ] App launches without database errors
- [ ] Existing history entries show (with disabled open actions)
- [ ] New received transfers have savedPath populated
- [ ] Completion popup appears after transfer
- [ ] Open file action works
- [ ] Show in folder action works

