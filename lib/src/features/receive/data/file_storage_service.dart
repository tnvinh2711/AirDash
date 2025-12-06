import 'dart:io';

import 'package:archive/archive.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_storage_service.g.dart';

/// Result of writing a file stream.
class WriteResult {
  /// Creates a [WriteResult].
  const WriteResult({required this.path, required this.checksum});

  /// Path where the file was written.
  final String path;

  /// MD5 checksum of the written data.
  final String checksum;
}

/// Service for managing file storage operations.
///
/// Handles file writing, checksum computation, and storage management.
class FileStorageService {
  /// Creates a [FileStorageService].
  ///
  /// If [receiveFolder] is provided, it will be used as the destination
  /// for received files. Otherwise, the platform's Downloads directory
  /// will be used.
  FileStorageService({String? receiveFolder}) : _receiveFolder = receiveFolder;

  final String? _receiveFolder;

  /// Gets the folder where received files should be saved.
  ///
  /// Returns the configured receive folder, or the platform's Downloads
  /// directory if not configured.
  Future<String> getReceiveFolder() async {
    if (_receiveFolder != null) {
      return _receiveFolder;
    }

    // Use Downloads directory on desktop, app documents on mobile
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Resolves a filename to avoid collisions.
  ///
  /// If a file with [fileName] already exists in [directory], appends
  /// a numeric suffix (e.g., "file (1).txt", "file (2).txt").
  Future<String> resolveFilename(String directory, String fileName) async {
    final basePath = p.join(directory, fileName);

    if (!await File(basePath).exists()) {
      return basePath;
    }

    final extension = p.extension(fileName);
    final nameWithoutExt = p.basenameWithoutExtension(fileName);

    var counter = 1;
    while (true) {
      final newName = extension.isNotEmpty
          ? '$nameWithoutExt ($counter)$extension'
          : '$nameWithoutExt ($counter)';
      final newPath = p.join(directory, newName);

      if (!await File(newPath).exists()) {
        return newPath;
      }
      counter++;
    }
  }

  /// Writes a stream of bytes to a file, computing MD5 checksum.
  ///
  /// Returns a [WriteResult] with the file path and computed checksum.
  Future<WriteResult> writeStream(
    String path,
    Stream<List<int>> stream,
  ) async {
    final file = File(path);
    final sink = file.openWrite();
    final output = AccumulatorSink<Digest>();
    final input = md5.startChunkedConversion(output);

    try {
      await for (final chunk in stream) {
        sink.add(chunk);
        input.add(chunk);
      }
      await sink.flush();
      input.close();

      final checksum = output.events.single.toString();
      return WriteResult(path: path, checksum: checksum);
    } finally {
      await sink.close();
    }
  }

  /// Deletes a file at the given path.
  ///
  /// Does nothing if the file does not exist.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets available storage space in bytes.
  Future<int> getAvailableSpace() async {
    final folder = await getReceiveFolder();
    final stat = await FileStat.stat(folder);
    // FileStat doesn't provide free space, use a reasonable default
    // In production, use platform-specific APIs
    if (stat.type == FileSystemEntityType.directory) {
      // Return a large value for now - actual implementation would
      // use platform channels for accurate free space
      return 10 * 1024 * 1024 * 1024; // 10 GB default
    }
    return 0;
  }

  /// Extracts a ZIP file to a directory.
  ///
  /// The ZIP file is extracted to a subdirectory named after the ZIP file
  /// (without extension). The original ZIP file is deleted after extraction.
  ///
  /// Returns the path to the extracted directory.
  Future<String> extractZip(String zipPath) async {
    final zipFile = File(zipPath);
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Create extraction directory based on ZIP filename
    final zipName = p.basenameWithoutExtension(zipPath);
    final parentDir = p.dirname(zipPath);
    var extractDir = p.join(parentDir, zipName);

    // Handle directory name collision
    var counter = 1;
    while (await Directory(extractDir).exists()) {
      extractDir = p.join(parentDir, '$zipName ($counter)');
      counter++;
    }

    await Directory(extractDir).create(recursive: true);

    // Extract all files
    for (final file in archive) {
      final filePath = p.join(extractDir, file.name);

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    // Delete the original ZIP file
    await zipFile.delete();

    return extractDir;
  }
}

/// Provides the [FileStorageService] instance.
@riverpod
FileStorageService fileStorageService(Ref ref) {
  return FileStorageService();
}
