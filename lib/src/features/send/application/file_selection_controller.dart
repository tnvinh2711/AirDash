import 'dart:convert';
import 'dart:io';

import 'package:flux/src/features/send/data/file_picker_service.dart';
import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'file_selection_controller.g.dart';

const _uuid = Uuid();

/// Size threshold for showing a warning (1GB).
const _sizeWarningThreshold = 1024 * 1024 * 1024;

/// Controller for managing the file selection queue.
///
/// Provides methods to add files via picker, paste text, and manage
/// the selection list (remove, clear). Selection is session-only and
/// clears on app restart.
@riverpod
class FileSelectionController extends _$FileSelectionController {
  @override
  List<SelectedItem> build() {
    // Session-only: start with empty list, no persistence
    return [];
  }

  /// Checks if a path is already in the selection queue.
  bool _isDuplicate(String? path) {
    if (path == null) return false;
    return state.any((item) => item.path == path);
  }

  /// Filters out duplicate items from a list.
  List<SelectedItem> _filterDuplicates(List<SelectedItem> items) {
    return items.where((item) => !_isDuplicate(item.path)).toList();
  }

  /// Opens the file picker and adds selected files to the queue.
  ///
  /// Skips files that are already in the selection (duplicate prevention).
  /// Returns the number of files added.
  Future<int> pickFiles() async {
    final pickerService = ref.read(filePickerServiceProvider);
    final items = await pickerService.pickFiles();
    final uniqueItems = _filterDuplicates(items);

    if (uniqueItems.isNotEmpty) {
      state = [...state, ...uniqueItems];
    }

    return uniqueItems.length;
  }

  /// Opens the folder picker and adds the selected folder to the queue.
  ///
  /// Skips if the folder is already in the selection (duplicate prevention).
  /// Returns true if a folder was added, false if cancelled or duplicate.
  Future<bool> pickFolder() async {
    final pickerService = ref.read(filePickerServiceProvider);
    final item = await pickerService.pickFolder();

    if (item != null && !_isDuplicate(item.path)) {
      state = [...state, item];
      return true;
    }

    return false;
  }

  /// Opens the media picker and adds selected photos/videos to the queue.
  ///
  /// Skips files that are already in the selection (duplicate prevention).
  /// Returns the number of media files added.
  Future<int> pickMedia() async {
    final pickerService = ref.read(filePickerServiceProvider);
    final items = await pickerService.pickMedia();
    final uniqueItems = _filterDuplicates(items);

    if (uniqueItems.isNotEmpty) {
      state = [...state, ...uniqueItems];
    }

    return uniqueItems.length;
  }

  /// Adds files from paths (e.g., from drag-and-drop).
  ///
  /// Skips paths that are already in the selection (duplicate prevention).
  /// Returns the number of items added.
  Future<int> addPaths(List<String> paths) async {
    if (paths.isEmpty) return 0;

    final items = <SelectedItem>[];

    for (final path in paths) {
      // Skip duplicates
      if (_isDuplicate(path)) continue;

      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.file) {
        final file = File(path);
        final size = await file.length();
        final name = path.split(Platform.pathSeparator).last;

        items.add(
          SelectedItem(
            id: _uuid.v4(),
            type: SelectedItemType.file,
            path: path,
            displayName: name,
            sizeEstimate: size,
          ),
        );
      } else if (entity == FileSystemEntityType.directory) {
        final folder = Directory(path);
        final size = await _estimateFolderSize(folder);
        final name = path.split(Platform.pathSeparator).last;

        items.add(
          SelectedItem(
            id: _uuid.v4(),
            type: SelectedItemType.folder,
            path: path,
            displayName: name,
            sizeEstimate: size,
          ),
        );
      }
    }

    if (items.isNotEmpty) {
      state = [...state, ...items];
    }

    return items.length;
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

  /// Adds text content to the selection queue.
  ///
  /// Creates a text item with a generated filename based on timestamp.
  void pasteText(String text) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final displayName = 'Pasted Text - $timestamp.txt';
    final sizeEstimate = utf8.encode(text).length;

    final item = SelectedItem(
      id: _uuid.v4(),
      type: SelectedItemType.text,
      displayName: displayName,
      sizeEstimate: sizeEstimate,
      content: text,
    );

    state = [...state, item];
  }

  /// Removes an item from the selection queue by its ID.
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Clears all items from the selection queue.
  void clear() {
    state = [];
  }

  /// Returns true if the selection queue is empty.
  bool get isEmpty => state.isEmpty;

  /// Returns the number of items in the selection queue.
  int get count => state.length;

  /// Returns the total estimated size of all selected items.
  int get totalSize => state.fold(0, (sum, item) => sum + item.sizeEstimate);

  /// Returns true if total size exceeds the warning threshold (1GB).
  bool get showSizeWarning => totalSize > _sizeWarningThreshold;

  /// Validates that all file/folder items still exist on disk.
  ///
  /// Returns a list of items that no longer exist. These should be
  /// removed or the user should be warned before transfer.
  Future<List<SelectedItem>> validateExistence() async {
    final missingItems = <SelectedItem>[];

    for (final item in state) {
      if (item.path == null) continue; // Text items have no path

      final exists = switch (item.type) {
        SelectedItemType.file ||
        SelectedItemType.media =>
          File(item.path!).existsSync(),
        SelectedItemType.folder => Directory(item.path!).existsSync(),
        SelectedItemType.text => true, // Text items always valid
      };

      if (!exists) {
        missingItems.add(item);
      }
    }

    return missingItems;
  }

  /// Removes items that no longer exist on disk.
  ///
  /// Returns the number of items removed.
  Future<int> removeInvalidItems() async {
    final missingItems = await validateExistence();

    if (missingItems.isEmpty) return 0;

    final missingIds = missingItems.map((e) => e.id).toSet();
    state = state.where((item) => !missingIds.contains(item.id)).toList();

    return missingItems.length;
  }
}
