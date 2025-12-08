import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'file_picker_service.g.dart';

/// Service for file and folder selection using the system picker.
///
/// Wraps [FilePicker] to provide a consistent API for selecting files
/// and folders across all platforms.
class FilePickerService {
  /// Creates a [FilePickerService] with an optional [Uuid] generator.
  FilePickerService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Opens the system file picker for selecting one or more files.
  ///
  /// Returns a list of [SelectedItem] for each selected file, or an empty
  /// list if the user cancels.
  Future<List<SelectedItem>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final items = <SelectedItem>[];
    for (final file in result.files) {
      if (file.path == null) continue;

      final fileInfo = File(file.path!);
      final size = await fileInfo.length();

      items.add(
        SelectedItem(
          id: _uuid.v4(),
          type: SelectedItemType.file,
          path: file.path,
          displayName: file.name,
          sizeEstimate: size,
        ),
      );
    }

    return items;
  }

  /// Opens the system folder picker for selecting a directory.
  ///
  /// Returns a [SelectedItem] for the selected folder, or null if cancelled.
  Future<SelectedItem?> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null) {
      return null;
    }

    final folder = Directory(path);
    final sizeEstimate = await _estimateFolderSize(folder);
    final folderName = path.split(Platform.pathSeparator).last;

    return SelectedItem(
      id: _uuid.v4(),
      type: SelectedItemType.folder,
      path: path,
      displayName: folderName,
      sizeEstimate: sizeEstimate,
    );
  }

  /// Opens the system media picker for selecting photos/videos.
  ///
  /// Returns a list of [SelectedItem] for each selected media file, or an empty
  /// list if the user cancels.
  Future<List<SelectedItem>> pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final items = <SelectedItem>[];
    for (final file in result.files) {
      if (file.path == null) continue;

      final fileInfo = File(file.path!);
      final size = await fileInfo.length();

      items.add(
        SelectedItem(
          id: _uuid.v4(),
          type: SelectedItemType.media,
          path: file.path,
          displayName: file.name,
          sizeEstimate: size,
        ),
      );
    }

    return items;
  }

  /// Estimates the total size of a folder by summing file sizes.
  Future<int> _estimateFolderSize(Directory folder) async {
    var totalSize = 0;

    await for (final entity in folder.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }
}

/// Provider for [FilePickerService].
@riverpod
FilePickerService filePickerService(Ref ref) {
  return FilePickerService();
}
