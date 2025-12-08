import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/send/data/dtos/handshake_request.dart';
import 'package:flux/src/features/send/data/transfer_client_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockDio extends Mock implements Dio {}

void main() {
  late TransferClientService service;
  late MockDio mockDio;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(CancelToken());
  });

  setUp(() async {
    mockDio = MockDio();
    service = TransferClientService(dio: mockDio);
    tempDir = await Directory.systemTemp.createTemp('transfer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TransferClientService', () {
    group('handshake', () {
      test('sends handshake request and returns response on success', () async {
        // Arrange
        const request = HandshakeRequest(
          fileName: 'test.txt',
          fileSize: 1024,
          fileType: 'txt',
          checksum: 'abc123',
          isFolder: false,
          fileCount: 1,
          senderDeviceId: 'device-123',
          senderAlias: 'My Device',
        );

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'accepted': true, 'sessionId': 'session-456'},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final response = await service.handshake(
          ip: '192.168.1.100',
          port: 8080,
          request: request,
        );

        // Assert
        expect(response.accepted, isTrue);
        expect(response.sessionId, equals('session-456'));
      });

      test('returns rejected response when server is busy', () async {
        // Arrange
        const request = HandshakeRequest(
          fileName: 'test.txt',
          fileSize: 1024,
          fileType: 'txt',
          checksum: 'abc123',
          isFolder: false,
          fileCount: 1,
          senderDeviceId: 'device-123',
          senderAlias: 'My Device',
        );

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'accepted': false, 'error': 'busy'},
            statusCode: 409,
            requestOptions: RequestOptions(),
          ),
        );

        // Act
        final response = await service.handshake(
          ip: '192.168.1.100',
          port: 8080,
          request: request,
        );

        // Assert
        expect(response.accepted, isFalse);
        expect(response.error, equals('busy'));
      });
    });

    group('upload', () {
      test('uploads file with progress callback', () async {
        // Arrange
        final testFile = File(p.join(tempDir.path, 'upload.txt'));
        await testFile.writeAsString('Test content for upload');

        final progressValues = <double>[];

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
            onSendProgress: any(named: 'onSendProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          // Simulate progress callback
          final onProgress =
              invocation.namedArguments[#onSendProgress] as ProgressCallback?;
          onProgress?.call(50, 100);
          onProgress?.call(100, 100);

          return Response(
            data: {
              'success': true,
              'savedPath': '/downloads/upload.txt',
              'checksumVerified': true,
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        // Act
        final response = await service.upload(
          ip: '192.168.1.100',
          port: 8080,
          sessionId: 'session-456',
          filePath: testFile.path,
          fileName: 'upload.txt',
          fileSize: await testFile.length(),
          onProgress: (sent, total) {
            progressValues.add(sent / total);
          },
        );

        // Assert
        expect(response.success, isTrue);
        expect(response.savedPath, equals('/downloads/upload.txt'));
        expect(response.checksumVerified, isTrue);
        expect(progressValues, contains(0.5));
        expect(progressValues, contains(1.0));
      });
    });
  });
}
