import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/domain/isolate_command.dart';
import 'package:flux/src/features/receive/domain/isolate_config.dart';

void main() {
  group('IsolateCommand', () {
    group('StartServerCommand', () {
      test('toMap and fromMap round-trip', () {
        const config = IsolateConfig(
          port: 53318,
          destinationPath: '/downloads',
          quickSaveEnabled: true,
        );
        const command = IsolateCommand.startServer(config: config);

        final map = command.toMap();
        final restored = IsolateCommand.fromMap(map);

        expect(restored, isA<StartServerCommand>());
        final startCmd = restored as StartServerCommand;
        expect(startCmd.config.port, 53318);
        expect(startCmd.config.destinationPath, '/downloads');
        expect(startCmd.config.quickSaveEnabled, true);
      });
    });

    group('StopServerCommand', () {
      test('toMap and fromMap round-trip', () {
        const command = IsolateCommand.stopServer();

        final map = command.toMap();
        final restored = IsolateCommand.fromMap(map);

        expect(restored, isA<StopServerCommand>());
      });
    });

    group('RespondHandshakeCommand', () {
      test('toMap and fromMap round-trip for accept', () {
        const command = IsolateCommand.respondHandshake(
          requestId: 'req-123',
          accepted: true,
        );

        final map = command.toMap();
        final restored = IsolateCommand.fromMap(map);

        expect(restored, isA<RespondHandshakeCommand>());
        final respCmd = restored as RespondHandshakeCommand;
        expect(respCmd.requestId, 'req-123');
        expect(respCmd.accepted, true);
      });

      test('toMap and fromMap round-trip for reject', () {
        const command = IsolateCommand.respondHandshake(
          requestId: 'req-456',
          accepted: false,
        );

        final map = command.toMap();
        final restored = IsolateCommand.fromMap(map);

        expect(restored, isA<RespondHandshakeCommand>());
        final respCmd = restored as RespondHandshakeCommand;
        expect(respCmd.requestId, 'req-456');
        expect(respCmd.accepted, false);
      });
    });

    test('fromMap throws on unknown type', () {
      expect(
        () => IsolateCommand.fromMap({'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}

