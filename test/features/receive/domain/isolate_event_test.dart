import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';

void main() {
  group('IsolateEvent', () {
    group('ServerStartedEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.serverStarted(port: 53318);

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<ServerStartedEvent>());
        expect((restored as ServerStartedEvent).port, 53318);
      });
    });

    group('ServerStoppedEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.serverStopped();

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<ServerStoppedEvent>());
      });
    });

    group('ServerErrorEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.serverError(message: 'Port in use');

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<ServerErrorEvent>());
        expect((restored as ServerErrorEvent).message, 'Port in use');
      });
    });

    group('IncomingRequestEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.incomingRequest(
          requestId: 'req-123',
          senderDeviceId: 'device-abc',
          senderAlias: 'John Phone',
          fileName: 'photo.jpg',
          fileSize: 1024000,
          fileCount: 1,
          isFolder: false,
        );

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<IncomingRequestEvent>());
        final req = restored as IncomingRequestEvent;
        expect(req.requestId, 'req-123');
        expect(req.senderDeviceId, 'device-abc');
        expect(req.senderAlias, 'John Phone');
        expect(req.fileName, 'photo.jpg');
        expect(req.fileSize, 1024000);
        expect(req.fileCount, 1);
        expect(req.isFolder, false);
      });
    });

    group('TransferProgressEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.transferProgress(
          sessionId: 'sess-123',
          bytesReceived: 512000,
          totalBytes: 1024000,
        );

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<TransferProgressEvent>());
        final prog = restored as TransferProgressEvent;
        expect(prog.sessionId, 'sess-123');
        expect(prog.bytesReceived, 512000);
        expect(prog.totalBytes, 1024000);
      });
    });

    group('TransferCompletedEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.transferCompleted(
          sessionId: 'sess-123',
          savedPath: '/downloads/photo.jpg',
          checksumVerified: true,
          fileName: 'photo.jpg',
          fileSize: 1024,
          fileCount: 1,
          senderAlias: 'TestSender',
        );

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<TransferCompletedEvent>());
        final comp = restored as TransferCompletedEvent;
        expect(comp.sessionId, 'sess-123');
        expect(comp.savedPath, '/downloads/photo.jpg');
        expect(comp.checksumVerified, true);
      });
    });

    group('TransferFailedEvent', () {
      test('toMap and fromMap round-trip', () {
        const event = IsolateEvent.transferFailed(
          sessionId: 'sess-123',
          reason: 'checksum_mismatch',
        );

        final map = event.toMap();
        final restored = IsolateEvent.fromMap(map);

        expect(restored, isA<TransferFailedEvent>());
        final fail = restored as TransferFailedEvent;
        expect(fail.sessionId, 'sess-123');
        expect(fail.reason, 'checksum_mismatch');
      });
    });

    test('fromMap throws on unknown type', () {
      expect(
        () => IsolateEvent.fromMap({'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
