import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compression_service.g.dart';

/// Result of folder compression including the ZIP path and file count.
class CompressionResult {
  /// Creates a [CompressionResult].
  const CompressionResult({required this.zipPath, required this.fileCount});

  /// Path to the created ZIP file.
  final String zipPath;

  /// Number of files in the archive.
  final int fileCount;
}

/// Service for file compression and checksum computation.
///
/// Provides methods to compute MD5 checksums for files and compress
/// folders into ZIP archives for transfer.
class CompressionService {
  /// Creates a [CompressionService] with an optional temp directory provider.
  ///
  /// If [tempDirProvider] is null, uses [getTemporaryDirectory].
  CompressionService({Future<Directory> Function()? tempDirProvider})
    : _tempDirProvider = tempDirProvider ?? getTemporaryDirectory;

  final Future<Directory> Function() _tempDirProvider;

  /// Computes the MD5 checksum of a file.
  ///
  /// Reads the file as a stream to handle large files efficiently.
  /// Returns the checksum as a lowercase hex string.
  ///
  /// Throws [FileSystemException] if the file does not exist.
  Future<String> computeChecksum(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Compresses a folder into a ZIP archive.
  ///
  /// Creates a temporary ZIP file containing all files and subdirectories.
  /// Returns the path to the created ZIP file.
  ///
  /// Throws [FileSystemException] if the folder does not exist.
  Future<String> compressFolder(String folderPath) async {
    final result = await compressFolderWithCount(folderPath);
    return result.zipPath;
  }

  /// Compresses a folder and returns both the ZIP path and file count.
  ///
  /// Creates a temporary ZIP file containing all files and subdirectories.
  /// Returns a [CompressionResult] with the ZIP path and file count.
  ///
  /// Throws [FileSystemException] if the folder does not exist.
  Future<CompressionResult> compressFolderWithCount(String folderPath) async {
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      throw FileSystemException('Folder not found', folderPath);
    }

    final archive = Archive();
    var fileCount = 0;

    await _addDirectoryToArchive(archive, folder, '', (count) {
      fileCount = count;
    });

    final zipBytes = ZipEncoder().encode(archive);

    // Create temp file
    final tempDir = await _tempDirProvider();
    final folderName = p.basename(folderPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = p.join(tempDir.path, '${folderName}_$timestamp.zip');

    await File(zipPath).writeAsBytes(zipBytes);

    return CompressionResult(zipPath: zipPath, fileCount: fileCount);
  }

  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
    void Function(int) onFileCount,
  ) async {
    var count = 0;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: dir.path);
        final archivePath = basePath.isEmpty
            ? relativePath
            : p.join(basePath, relativePath);

        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
        count++;
      }
    }

    onFileCount(count);
  }

  /// Deletes a temporary file created during compression.
  ///
  /// Safe to call even if the file doesn't exist.
  Future<void> cleanup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Provider for [CompressionService].
@riverpod
CompressionService compressionService(Ref ref) {
  return CompressionService();
}
