import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/send/data/compression_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late CompressionService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('compression_test_');
    service = CompressionService(tempDirProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CompressionService', () {
    group('computeChecksum', () {
      test('computes MD5 checksum for file', () async {
        // Arrange
        final testFile = File(p.join(tempDir.path, 'test.txt'));
        await testFile.writeAsString('Hello, World!');

        // Act
        final checksum = await service.computeChecksum(testFile.path);

        // Assert
        // MD5 of "Hello, World!" is 65a8e27d8879283831b664bd8b7f0ad4
        expect(checksum, equals('65a8e27d8879283831b664bd8b7f0ad4'));
      });

      test('computes different checksums for different content', () async {
        // Arrange
        final file1 = File(p.join(tempDir.path, 'file1.txt'));
        final file2 = File(p.join(tempDir.path, 'file2.txt'));
        await file1.writeAsString('Content A');
        await file2.writeAsString('Content B');

        // Act
        final checksum1 = await service.computeChecksum(file1.path);
        final checksum2 = await service.computeChecksum(file2.path);

        // Assert
        expect(checksum1, isNot(equals(checksum2)));
      });

      test('computes same checksum for same content', () async {
        // Arrange
        final file1 = File(p.join(tempDir.path, 'file1.txt'));
        final file2 = File(p.join(tempDir.path, 'file2.txt'));
        await file1.writeAsString('Same content');
        await file2.writeAsString('Same content');

        // Act
        final checksum1 = await service.computeChecksum(file1.path);
        final checksum2 = await service.computeChecksum(file2.path);

        // Assert
        expect(checksum1, equals(checksum2));
      });

      test('throws when file does not exist', () async {
        // Arrange
        final nonExistentPath = p.join(tempDir.path, 'nonexistent.txt');

        // Act & Assert
        expect(
          () => service.computeChecksum(nonExistentPath),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('handles empty file', () async {
        // Arrange
        final emptyFile = File(p.join(tempDir.path, 'empty.txt'));
        await emptyFile.writeAsString('');

        // Act
        final checksum = await service.computeChecksum(emptyFile.path);

        // Assert
        // MD5 of empty string is d41d8cd98f00b204e9800998ecf8427e
        expect(checksum, equals('d41d8cd98f00b204e9800998ecf8427e'));
      });

      test('handles large file', () async {
        // Arrange
        final largeFile = File(p.join(tempDir.path, 'large.bin'));
        // Create a 1MB file
        final bytes = List.generate(1024 * 1024, (i) => i % 256);
        await largeFile.writeAsBytes(bytes);

        // Act
        final checksum = await service.computeChecksum(largeFile.path);

        // Assert
        expect(checksum, isNotEmpty);
        expect(checksum.length, equals(32)); // MD5 is 32 hex chars
      });
    });

    group('compressFolder', () {
      test('compresses folder to ZIP file', () async {
        // Arrange
        final folder = Directory(p.join(tempDir.path, 'test_folder'));
        await folder.create();
        await File(p.join(folder.path, 'file1.txt')).writeAsString('Content 1');
        await File(p.join(folder.path, 'file2.txt')).writeAsString('Content 2');

        // Act
        final zipPath = await service.compressFolder(folder.path);

        // Assert
        expect(zipPath, endsWith('.zip'));
        expect(await File(zipPath).exists(), isTrue);

        // Verify ZIP contents
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final fileNames = archive.files.map((f) => f.name).toList();
        expect(fileNames, contains('file1.txt'));
        expect(fileNames, contains('file2.txt'));
      });

      test('preserves directory structure in ZIP', () async {
        // Arrange
        final folder = Directory(p.join(tempDir.path, 'nested_folder'));
        await folder.create();
        final subDir = Directory(p.join(folder.path, 'subdir'));
        await subDir.create();
        await File(p.join(folder.path, 'root.txt')).writeAsString('Root');
        await File(p.join(subDir.path, 'nested.txt')).writeAsString('Nested');

        // Act
        final zipPath = await service.compressFolder(folder.path);

        // Assert
        final zipBytes = await File(zipPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);
        final fileNames = archive.files.map((f) => f.name).toList();
        expect(fileNames, contains('root.txt'));
        expect(fileNames, anyElement(contains('subdir')));
        expect(fileNames, anyElement(contains('nested.txt')));
      });

      test('returns file count', () async {
        // Arrange
        final folder = Directory(p.join(tempDir.path, 'count_folder'));
        await folder.create();
        await File(p.join(folder.path, 'a.txt')).writeAsString('A');
        await File(p.join(folder.path, 'b.txt')).writeAsString('B');
        await File(p.join(folder.path, 'c.txt')).writeAsString('C');

        // Act
        final result = await service.compressFolderWithCount(folder.path);

        // Assert
        expect(result.fileCount, equals(3));
      });

      test('throws when folder does not exist', () async {
        // Arrange
        final nonExistentPath = p.join(tempDir.path, 'nonexistent_folder');

        // Act & Assert
        expect(
          () => service.compressFolder(nonExistentPath),
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('cleanup', () {
      test('deletes temp file', () async {
        // Arrange
        final tempFile = File(p.join(tempDir.path, 'temp.zip'));
        await tempFile.writeAsString('temp content');
        expect(await tempFile.exists(), isTrue);

        // Act
        await service.cleanup(tempFile.path);

        // Assert
        expect(await tempFile.exists(), isFalse);
      });

      test('does not throw when file does not exist', () async {
        // Arrange
        final nonExistentPath = p.join(tempDir.path, 'nonexistent.zip');

        // Act & Assert - should not throw
        await service.cleanup(nonExistentPath);
      });
    });
  });
}
