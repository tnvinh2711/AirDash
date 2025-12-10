# Research: File Open Actions

**Feature**: 013-file-open-actions | **Date**: 2025-12-08

## Research Tasks

### 1. Cross-Platform File Opening Package

**Decision**: Use `open_filex` package (v4.7.0)

**Rationale**:
- Supports all 5 target platforms: Android, iOS, macOS, Windows, Linux
- Fork of `open_file` with critical fixes (no REQUEST_INSTALL_PACKAGES permission, Gradle 8+ compatibility)
- 413 likes, 351k downloads on pub.dev - well-maintained
- Simple API: `OpenFilex.open(filePath)` returns result with status
- Uses platform-native mechanisms: Android Intent, iOS DocumentInteraction, Desktop FFI

**Alternatives Considered**:
- `url_launcher`: Primarily for URLs; `file://` scheme support is inconsistent across platforms
- `open_file`: Original package, but has permission issues on Android (REQUEST_INSTALL_PACKAGES)

**Implementation**:
```dart
import 'package:open_filex/open_filex.dart';

// Open file with default application
final result = await OpenFilex.open('/path/to/file.pdf');
if (result.type != ResultType.done) {
  // Handle error: result.message contains error details
}
```

---

### 2. Show in Folder Functionality

**Decision**: Platform-specific implementation using `Process.run`

**Rationale**:
- No single package handles "reveal in file manager" across all platforms
- Each platform has a specific command to reveal files in their file manager

**Implementation**:
```dart
import 'dart:io';

Future<bool> showInFolder(String filePath) async {
  if (Platform.isMacOS) {
    // macOS: open -R reveals file in Finder
    await Process.run('open', ['-R', filePath]);
  } else if (Platform.isWindows) {
    // Windows: explorer /select, reveals file in Explorer
    await Process.run('explorer', ['/select,', filePath]);
  } else if (Platform.isLinux) {
    // Linux: xdg-open opens parent directory (no select)
    final dir = File(filePath).parent.path;
    await Process.run('xdg-open', [dir]);
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Mobile: Open parent directory (limited support)
    final dir = File(filePath).parent.path;
    await OpenFilex.open(dir);
  }
  return true;
}
```

---

### 3. Database Migration for savedPath Column

**Decision**: Add nullable `savedPath` column with schema version 2

**Rationale**:
- Current schema version is 1
- Adding nullable column is non-destructive migration
- Existing entries will have `null` savedPath (handled per clarification: disable open actions)

**Implementation**:
```dart
// In transfer_history_table.dart
TextColumn get savedPath => text().nullable()();

// In app_database.dart
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
        // Add savedPath column to existing table
        await m.addColumn(transferHistoryTable, transferHistoryTable.savedPath);
      }
    },
  );
}
```

---

### 4. File Existence Verification

**Decision**: Check file existence before enabling open actions

**Rationale**:
- Files may be moved/deleted after transfer
- Need graceful handling when file no longer exists
- Per spec: show "File not found" error if file missing

**Implementation**:
```dart
Future<bool> fileExists(String? path) async {
  if (path == null) return false;
  return File(path).exists();
}
```

---

### 5. Completion Popup Dialog Design

**Decision**: Use `showDialog` with custom `AlertDialog` widget

**Rationale**:
- Follows Flutter Material Design patterns
- Modal dialog ensures user attention
- Per clarification: stays visible until user dismisses
- Each transfer shows its own popup (multiple popups possible)

**Implementation Pattern**:
```dart
Future<void> showTransferCompleteDialog(
  BuildContext context,
  CompletedTransferInfo transfer,
) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => TransferCompleteDialog(transfer: transfer),
  );
}
```

---

## Dependencies to Add

```yaml
dependencies:
  open_filex: ^4.7.0
```

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| How long should popup stay visible? | Until user dismisses (no auto-dismiss) |
| What about existing history entries? | Keep but disable open actions ("Path not available") |
| Multiple transfers at once? | Each shows its own popup |

## Platform-Specific Notes

| Platform | Open File | Show in Folder |
|----------|-----------|----------------|
| macOS | `open_filex` | `open -R <path>` |
| Windows | `open_filex` | `explorer /select, <path>` |
| Linux | `open_filex` | `xdg-open <parent-dir>` |
| Android | `open_filex` | Open parent directory |
| iOS | `open_filex` | Open parent directory |

