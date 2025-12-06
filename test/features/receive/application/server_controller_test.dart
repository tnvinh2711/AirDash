import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/data/file_storage_service.dart';

void main() {
  late ProviderContainer container;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('server_controller_test_');

    container = ProviderContainer(
      overrides: [
        fileStorageServiceProvider.overrideWithValue(
          FileStorageService(receiveFolder: tempDir.path),
        ),
      ],
    );
  });

  tearDown(() async {
    // Stop server if running
    final controller = container.read(serverControllerProvider.notifier);
    final state = container.read(serverControllerProvider);
    if (state.valueOrNull?.isRunning ?? false) {
      await controller.stopServer();
    }
    container.dispose();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ServerController', () {
    test('initial state is stopped', () async {
      final state = await container.read(serverControllerProvider.future);
      expect(state.isRunning, isFalse);
      expect(state.port, isNull);
      expect(state.isBroadcasting, isFalse);
    });

    test('startServer starts HTTP server', () async {
      final controller = container.read(serverControllerProvider.notifier);

      await controller.startServer();

      final state = await container.read(serverControllerProvider.future);
      expect(state.isRunning, isTrue);
      expect(state.port, isNotNull);
      expect(state.port, greaterThan(0));
    });

    test('stopServer stops HTTP server', () async {
      final controller = container.read(serverControllerProvider.notifier);

      await controller.startServer();
      await controller.stopServer();

      final state = await container.read(serverControllerProvider.future);
      expect(state.isRunning, isFalse);
      expect(state.port, isNull);
    });

    test('toggleServer starts when stopped', () async {
      final controller = container.read(serverControllerProvider.notifier);

      await controller.toggleServer();

      final state = await container.read(serverControllerProvider.future);
      expect(state.isRunning, isTrue);
    });

    test('toggleServer stops when running', () async {
      final controller = container.read(serverControllerProvider.notifier);

      await controller.startServer();
      await controller.toggleServer();

      final state = await container.read(serverControllerProvider.future);
      expect(state.isRunning, isFalse);
    });

    test('startServer is idempotent', () async {
      final controller = container.read(serverControllerProvider.notifier);

      await controller.startServer();
      final state1 = await container.read(serverControllerProvider.future);
      final port1 = state1.port;

      await controller.startServer();
      final state2 = await container.read(serverControllerProvider.future);
      final port2 = state2.port;

      expect(port1, equals(port2));
    });
  });
}
