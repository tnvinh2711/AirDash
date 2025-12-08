import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/data/file_storage_service.dart';

void main() {
  late FileStorageService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_storage_test_');
    service = FileStorageService(receiveFolder: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileStorageService', () {
    group('getReceiveFolder', () {
      test('returns configured receive folder', () async {
        final folder = await service.getReceiveFolder();
        expect(folder, equals(tempDir.path));
      });
    });

    group('resolveFilename', () {
      test('returns original filename when no collision', () async {
        final result = await service.resolveFilename(
          tempDir.path,
          'test.txt',
        );
        expect(result, endsWith('test.txt'));
      });

      test('appends (1) suffix on first collision', () async {
        // Create existing file
        await File('${tempDir.path}/test.txt').create();

        final result = await service.resolveFilename(
          tempDir.path,
          'test.txt',
        );
        expect(result, endsWith('test (1).txt'));
      });

      test('increments suffix on multiple collisions', () async {
        // Create multiple existing files
        await File('${tempDir.path}/test.txt').create();
        await File('${tempDir.path}/test (1).txt').create();
        await File('${tempDir.path}/test (2).txt').create();

        final result = await service.resolveFilename(
          tempDir.path,
          'test.txt',
        );
        expect(result, endsWith('test (3).txt'));
      });

      test('handles filenames without extension', () async {
        await File('${tempDir.path}/readme').create();

        final result = await service.resolveFilename(
          tempDir.path,
          'readme',
        );
        expect(result, endsWith('readme (1)'));
      });
    });

    group('writeStream', () {
      test('writes stream data to file and returns checksum', () async {
        const data = 'Hello, World!';
        final stream = Stream.value(data.codeUnits);

        final result = await service.writeStream(
          '${tempDir.path}/output.txt',
          stream,
        );

        expect(result.path, equals('${tempDir.path}/output.txt'));
        expect(result.checksum, isNotEmpty);
        expect(result.checksum.length, equals(32)); // MD5 hex length

        // Verify file content
        final content = await File('${tempDir.path}/output.txt').readAsString();
        expect(content, equals(data));
      });

      test('computes correct MD5 checksum', () async {
        // "Hello, World!" MD5 = 65a8e27d8879283831b664bd8b7f0ad4
        const data = 'Hello, World!';
        final stream = Stream.value(data.codeUnits);

        final result = await service.writeStream(
          '${tempDir.path}/output.txt',
          stream,
        );

        expect(
          result.checksum.toLowerCase(),
          equals('65a8e27d8879283831b664bd8b7f0ad4'),
        );
      });
    });

    group('deleteFile', () {
      test('deletes existing file', () async {
        final file = File('${tempDir.path}/to_delete.txt');
        await file.writeAsString('content');
        expect(await file.exists(), isTrue);

        await service.deleteFile(file.path);

        expect(await file.exists(), isFalse);
      });

      test('does not throw when file does not exist', () async {
        await expectLater(
          service.deleteFile('${tempDir.path}/nonexistent.txt'),
          completes,
        );
      });
    });

    group('getAvailableSpace', () {
      test('returns positive value', () async {
        final space = await service.getAvailableSpace();
        expect(space, greaterThan(0));
      });
    });

    group('extractZip', () {
      test('extracts ZIP file to directory', () async {
        // Create a ZIP file with test content
        final archive = Archive()
          ..addFile(ArchiveFile(
            'test.txt',
            'Hello, World!'.length,
            'Hello, World!'.codeUnits,
          ));

        final zipData = ZipEncoder().encode(archive);
        final zipPath = '${tempDir.path}/test.zip';
        await File(zipPath).writeAsBytes(zipData);

        // Extract
        final extractedPath = await service.extractZip(zipPath);

        // Verify extraction
        expect(Directory(extractedPath).existsSync(), isTrue);
        expect(extractedPath, endsWith('test'));

        final extractedFile = File('$extractedPath/test.txt');
        expect(extractedFile.existsSync(), isTrue);
        expect(await extractedFile.readAsString(), equals('Hello, World!'));

        // Verify original ZIP is deleted
        expect(File(zipPath).existsSync(), isFalse);
      });

      test('preserves nested directory structure', () async {
        // Create a ZIP with nested directories
        final archive = Archive()
          ..addFile(ArchiveFile(
            'folder/subfolder/nested.txt',
            'Nested content'.length,
            'Nested content'.codeUnits,
          ))
          ..addFile(ArchiveFile(
            'folder/root.txt',
            'Root content'.length,
            'Root content'.codeUnits,
          ));

        final zipData = ZipEncoder().encode(archive);
        final zipPath = '${tempDir.path}/nested.zip';
        await File(zipPath).writeAsBytes(zipData);

        // Extract
        final extractedPath = await service.extractZip(zipPath);

        // Verify nested structure
        final nestedFile = File('$extractedPath/folder/subfolder/nested.txt');
        expect(nestedFile.existsSync(), isTrue);
        expect(await nestedFile.readAsString(), equals('Nested content'));

        final rootFile = File('$extractedPath/folder/root.txt');
        expect(rootFile.existsSync(), isTrue);
        expect(await rootFile.readAsString(), equals('Root content'));
      });

      test('handles directory name collision', () async {
        // Create existing directory
        await Directory('${tempDir.path}/collision').create();

        // Create ZIP
        final archive = Archive()
          ..addFile(ArchiveFile(
            'file.txt',
            'Content'.length,
            'Content'.codeUnits,
          ));

        final zipData = ZipEncoder().encode(archive);
        final zipPath = '${tempDir.path}/collision.zip';
        await File(zipPath).writeAsBytes(zipData);

        // Extract
        final extractedPath = await service.extractZip(zipPath);

        // Should create collision (1) directory
        expect(extractedPath, endsWith('collision (1)'));
        expect(Directory(extractedPath).existsSync(), isTrue);
      });
    });
  });
}
