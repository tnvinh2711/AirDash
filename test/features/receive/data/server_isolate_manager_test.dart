import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/receive/data/server_isolate_manager.dart';
import 'package:flux/src/features/receive/domain/isolate_config.dart';
import 'package:flux/src/features/receive/domain/isolate_event.dart';

void main() {
  group('ServerIsolateManager', () {
    late ServerIsolateManager manager;

    setUp(() {
      manager = ServerIsolateManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('initial state is not running', () {
      expect(manager.isRunning, false);
    });

    test('start spawns isolate and emits ServerStartedEvent', () async {
      const config = IsolateConfig(
        port: 0, // Use ephemeral port
        destinationPath: '/tmp/test',
        quickSaveEnabled: false,
      );

      final events = <IsolateEvent>[];
      final subscription = manager.events.listen(events.add);

      await manager.start(config);

      // Wait for server started event
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(manager.isRunning, true);
      expect(events, isNotEmpty);
      expect(events.first, isA<ServerStartedEvent>());

      await subscription.cancel();
    });

    test('stop terminates isolate and emits ServerStoppedEvent', () async {
      const config = IsolateConfig(
        port: 0,
        destinationPath: '/tmp/test',
        quickSaveEnabled: false,
      );

      final events = <IsolateEvent>[];
      final subscription = manager.events.listen(events.add);

      await manager.start(config);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await manager.stop();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(manager.isRunning, false);
      expect(
        events.any((e) => e is ServerStoppedEvent),
        true,
        reason: 'Should emit ServerStoppedEvent',
      );

      await subscription.cancel();
    });

    test('respondHandshake sends command to isolate', () async {
      const config = IsolateConfig(
        port: 0,
        destinationPath: '/tmp/test',
        quickSaveEnabled: false,
      );

      await manager.start(config);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // This should not throw
      manager.respondHandshake(requestId: 'req-123', accepted: true);

      await manager.stop();
    });

    test('dispose cleans up resources', () async {
      const config = IsolateConfig(
        port: 0,
        destinationPath: '/tmp/test',
        quickSaveEnabled: false,
      );

      await manager.start(config);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await manager.dispose();

      expect(manager.isRunning, false);
    });
  });
}

