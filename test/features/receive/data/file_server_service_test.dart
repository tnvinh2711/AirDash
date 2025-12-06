import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/data/file_server_service.dart';
import 'package:flux/src/features/receive/data/file_storage_service.dart';
import 'package:http/http.dart' as http;

void main() {
  late FileServerService serverService;
  late FileStorageService storageService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_server_test_');
    storageService = FileStorageService(receiveFolder: tempDir.path);
    serverService = FileServerService(storageService: storageService);
  });

  tearDown(() async {
    // Server may be running from tests, need to stop it
    await serverService.stop();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileServerService', () {
    group('start/stop', () {
      test('starts server on available port', () async {
        final port = await serverService.start();

        expect(port, greaterThan(0));
        expect(serverService.isRunning, isTrue);
        expect(serverService.port, equals(port));
      });

      test('stops server', () async {
        await serverService.start();
        await serverService.stop();

        expect(serverService.isRunning, isFalse);
        expect(serverService.port, isNull);
      });

      test('returns same port if already running', () async {
        final port1 = await serverService.start();
        final port2 = await serverService.start();

        expect(port1, equals(port2));
      });
    });

    group('POST /api/v1/info (handshake)', () {
      test('accepts valid handshake and returns session ID', () async {
        final port = await serverService.start();

        final response = await http.post(
          Uri.parse('http://localhost:$port/api/v1/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fileName': 'test.txt',
            'fileSize': 100,
            'fileType': 'text/plain',
            'checksum': 'd41d8cd98f00b204e9800998ecf8427e',
            'isFolder': false,
            'fileCount': 1,
            'senderDeviceId': 'test-device',
            'senderAlias': 'Test Device',
          }),
        );

        expect(response.statusCode, equals(200));
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['accepted'], isTrue);
        expect(body['sessionId'], isNotEmpty);
      });

      test('rejects handshake when busy', () async {
        final port = await serverService.start();

        // First handshake
        await http.post(
          Uri.parse('http://localhost:$port/api/v1/info'),
          headers: {'Content-Type': 'application/json'},
          body: _validHandshakeJson(),
        );

        // Second handshake while first is pending
        final response = await http.post(
          Uri.parse('http://localhost:$port/api/v1/info'),
          headers: {'Content-Type': 'application/json'},
          body: _validHandshakeJson(),
        );

        expect(response.statusCode, equals(409));
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['accepted'], isFalse);
        expect(body['error'], equals('busy'));
      });

      test('rejects handshake with missing checksum', () async {
        final port = await serverService.start();

        final response = await http.post(
          Uri.parse('http://localhost:$port/api/v1/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fileName': 'test.txt',
            'fileSize': 100,
            'fileType': 'text/plain',
            'isFolder': false,
            'fileCount': 1,
            'senderDeviceId': 'test-device',
            'senderAlias': 'Test Device',
          }),
        );

        expect(response.statusCode, equals(400));
      });
    });
  });
}

String _validHandshakeJson() {
  return jsonEncode({
    'fileName': 'test.txt',
    'fileSize': 100,
    'fileType': 'text/plain',
    'checksum': 'd41d8cd98f00b204e9800998ecf8427e',
    'isFolder': false,
    'fileCount': 1,
    'senderDeviceId': 'test-device',
    'senderAlias': 'Test Device',
  });
}
