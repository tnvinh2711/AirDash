import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flux/src/core/providers/file_open_result.dart';
import 'package:open_filex/open_filex.dart';

/// Service for opening files and revealing them in the system file manager.
///
/// Uses platform-native APIs via the `open_filex` package for cross-platform
/// file opening capabilities.
class FileOpenService {
  /// Opens a file with the system's default application.
  ///
  /// Returns [FileOpenResult] indicating success or the type of failure.
  Future<FileOpenResult> openFile(String filePath) async {
    debugPrint('[FileOpenService] Opening file: $filePath');

    if (!await fileExists(filePath)) {
      debugPrint('[FileOpenService] File not found: $filePath');
      return FileOpenResult.fileNotFound;
    }

    try {
      final result = await OpenFilex.open(filePath);
      final mappedResult = _mapOpenResult(result);
      debugPrint('[FileOpenService] Open result: $mappedResult');
      return mappedResult;
    } catch (e) {
      debugPrint('[FileOpenService] Error opening file: $e');
      return FileOpenResult.unknownError;
    }
  }

  /// Reveals a file in the system's file manager.
  ///
  /// On desktop platforms (macOS, Windows, Linux): Opens the file manager
  /// with the file selected.
  ///
  /// On mobile platforms (iOS, Android): Opens the parent directory.
  Future<FileOpenResult> showInFolder(String filePath) async {
    debugPrint('[FileOpenService] Showing in folder: $filePath');

    if (!await fileExists(filePath)) {
      debugPrint('[FileOpenService] File not found: $filePath');
      return FileOpenResult.fileNotFound;
    }

    try {
      FileOpenResult result;
      if (Platform.isMacOS) {
        // macOS: Use 'open -R' to reveal in Finder
        debugPrint('[FileOpenService] Using macOS Finder reveal');
        final processResult = await Process.run('open', ['-R', filePath]);
        result = processResult.exitCode == 0
            ? FileOpenResult.success
            : FileOpenResult.unknownError;
      } else if (Platform.isWindows) {
        // Windows: Use 'explorer /select,' to reveal in Explorer
        debugPrint('[FileOpenService] Using Windows Explorer reveal');
        await Process.run('explorer', ['/select,', filePath]);
        // Explorer returns 1 even on success, so we check differently
        result = FileOpenResult.success;
      } else if (Platform.isLinux) {
        // Linux: Use 'xdg-open' to open parent directory
        final parentDir = File(filePath).parent.path;
        debugPrint('[FileOpenService] Using Linux xdg-open: $parentDir');
        final processResult = await Process.run('xdg-open', [parentDir]);
        result = processResult.exitCode == 0
            ? FileOpenResult.success
            : FileOpenResult.unknownError;
      } else {
        // iOS/Android: Open parent directory with open_filex
        final parentDir = File(filePath).parent.path;
        debugPrint('[FileOpenService] Using mobile open: $parentDir');
        final openResult = await OpenFilex.open(parentDir);
        result = _mapOpenResult(openResult);
      }
      debugPrint('[FileOpenService] Show in folder result: $result');
      return result;
    } catch (e) {
      debugPrint('[FileOpenService] Error showing in folder: $e');
      return FileOpenResult.unknownError;
    }
  }

  /// Checks if a file exists at the given path.
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Maps [OpenResult] from open_filex to our [FileOpenResult].
  FileOpenResult _mapOpenResult(OpenResult result) {
    switch (result.type) {
      case ResultType.done:
        return FileOpenResult.success;
      case ResultType.fileNotFound:
        return FileOpenResult.fileNotFound;
      case ResultType.noAppToOpen:
        return FileOpenResult.noAppAvailable;
      case ResultType.permissionDenied:
        return FileOpenResult.permissionDenied;
      case ResultType.error:
        return FileOpenResult.unknownError;
    }
  }
}
