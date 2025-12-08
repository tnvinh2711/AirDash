// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/discovery/application/discovery_controller.dart';
import 'package:flux/src/features/discovery/data/discovery_repository.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class FakeLocalDeviceInfo extends Fake implements LocalDeviceInfo {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLocalDeviceInfo());
  });

  Device createTestDevice({
    String serviceInstanceName = 'TestDevice',
    String ip = '192.168.1.100',
    int port = 8080,
  }) {
    return Device(
      serviceInstanceName: serviceInstanceName,
      ip: ip,
      port: port,
      alias: 'Test Device',
      deviceType: DeviceType.phone,
      os: 'Android 14',
      lastSeen: DateTime.now(),
    );
  }

  LocalDeviceInfo createTestLocalDeviceInfo() {
    return const LocalDeviceInfo(
      alias: 'My Device',
      deviceType: DeviceType.phone,
      os: 'Android 14',
      port: 8080,
    );
  }

  group('DiscoveryController', () {
    group('startScan', () {
      test('updates isScanning state to true', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.isScanning, isTrue);
      });

      test('does not restart scan if already scanning', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        await controller.startScan();

        verify(() => mockRepository.startScan()).called(1);
      });
    });

    group('stopScan', () {
      test('updates isScanning state to false', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);
        when(() => mockRepository.stopScan()).thenAnswer((_) async {});

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        await controller.stopScan();

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.isScanning, isFalse);
      });

      test('preserves devices list after stopping', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);
        when(() => mockRepository.stopScan()).thenAnswer((_) async {});

        // Keep the provider alive by listening to it
        final subscription = container.listen(
          discoveryControllerProvider,
          (_, __) {},
        );
        addTearDown(subscription.close);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        eventController.add(DeviceFoundEvent(createTestDevice()));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Verify device was added
        var state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.devices.length, equals(1));

        await controller.stopScan();

        // Devices are preserved after stopping scan (not cleared)
        state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.devices.length, equals(1));
      });
    });

    group('startBroadcast', () {
      test('updates isBroadcasting state to true', () async {
        final mockRepository = MockDiscoveryRepository();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        when(
          () => mockRepository.startBroadcast(any()),
        ).thenAnswer((_) async => 'MyDevice');

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startBroadcast(createTestLocalDeviceInfo());

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.isBroadcasting, isTrue);
        expect(state?.ownServiceInstanceName, equals('MyDevice'));
      });

      test('does not restart broadcast if already broadcasting', () async {
        final mockRepository = MockDiscoveryRepository();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        when(
          () => mockRepository.startBroadcast(any()),
        ).thenAnswer((_) async => 'MyDevice');

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startBroadcast(createTestLocalDeviceInfo());
        await controller.startBroadcast(createTestLocalDeviceInfo());

        verify(() => mockRepository.startBroadcast(any())).called(1);
      });
    });

    group('stopBroadcast', () {
      test('updates isBroadcasting state to false', () async {
        final mockRepository = MockDiscoveryRepository();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        when(
          () => mockRepository.startBroadcast(any()),
        ).thenAnswer((_) async => 'MyDevice');
        when(() => mockRepository.stopBroadcast()).thenAnswer((_) async {});

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startBroadcast(createTestLocalDeviceInfo());
        await controller.stopBroadcast();

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.isBroadcasting, isFalse);
        expect(state?.ownServiceInstanceName, isNull);
      });
    });

    group('device events', () {
      test('adds device to list on DeviceFoundEvent', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);

        // Keep the provider alive by listening to it
        final subscription = container.listen(
          discoveryControllerProvider,
          (_, __) {},
        );
        addTearDown(subscription.close);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();

        // Verify scanning state
        final scanningState = container
            .read(discoveryControllerProvider)
            .valueOrNull;
        expect(scanningState?.isScanning, isTrue);

        // Add event and pump the event queue
        eventController.add(DeviceFoundEvent(createTestDevice()));
        await Future.microtask(() {});
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.devices.length, equals(1));
        expect(state?.devices.first.serviceInstanceName, equals('TestDevice'));
      });

      test('removes device from list on DeviceLostEvent after grace period',
          () {
        fakeAsync((async) {
          final mockRepository = MockDiscoveryRepository();
          final eventController = StreamController<DiscoveryEvent>.broadcast();
          final container = ProviderContainer(
            overrides: [
              discoveryRepositoryProvider.overrideWithValue(mockRepository),
            ],
          );

          when(
            () => mockRepository.startScan(),
          ).thenAnswer((_) => eventController.stream);

          // Keep the provider alive by listening to it
          final subscription = container.listen(
            discoveryControllerProvider,
            (_, __) {},
          );

          // Wait for the provider to be ready
          async.flushMicrotasks();

          final controller =
              container.read(discoveryControllerProvider.notifier);

          controller.startScan();
          async.flushMicrotasks();

          eventController.add(DeviceFoundEvent(createTestDevice()));
          async.flushMicrotasks();

          // Device should be in the list
          var state = container.read(discoveryControllerProvider).valueOrNull;
          expect(state?.devices, hasLength(1));

          eventController.add(DeviceLostEvent('TestDevice'));
          async.flushMicrotasks();

          // Device should still be in the list (grace period not expired)
          state = container.read(discoveryControllerProvider).valueOrNull;
          expect(state?.devices, hasLength(1));

          // Fast-forward past the 30-second grace period
          async.elapse(const Duration(seconds: 31));

          // Now device should be removed
          state = container.read(discoveryControllerProvider).valueOrNull;
          expect(state?.devices, isEmpty);

          // Cleanup
          subscription.close();
          eventController.close();
          container.dispose();
        });
      });

      test('updates device on DeviceUpdatedEvent', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);

        // Keep the provider alive by listening to it
        final subscription = container.listen(
          discoveryControllerProvider,
          (_, __) {},
        );
        addTearDown(subscription.close);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        eventController.add(DeviceFoundEvent(createTestDevice()));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final updatedDevice = createTestDevice(ip: '192.168.1.200');
        eventController.add(DeviceUpdatedEvent(updatedDevice));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.devices.length, equals(1));
        expect(state?.devices.first.ip, equals('192.168.1.200'));
      });

      test('sets error on DiscoveryErrorEvent', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);

        // Keep the provider alive by listening to it
        final subscription = container.listen(
          discoveryControllerProvider,
          (_, __) {},
        );
        addTearDown(subscription.close);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        eventController.add(DiscoveryErrorEvent('Network error'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.error, equals('Network error'));
      });
    });

    group('self-filtering', () {
      test('filters out own device from discovery list', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);
        when(
          () => mockRepository.startBroadcast(any()),
        ).thenAnswer((_) async => 'MyDevice');

        // Keep the provider alive by listening to it
        final subscription = container.listen(
          discoveryControllerProvider,
          (_, __) {},
        );
        addTearDown(subscription.close);

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startBroadcast(createTestLocalDeviceInfo());
        await controller.startScan();

        // Add own device (should be filtered)
        eventController.add(
          DeviceFoundEvent(createTestDevice(serviceInstanceName: 'MyDevice')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Add other device (should be added)
        eventController.add(
          DeviceFoundEvent(
            createTestDevice(serviceInstanceName: 'OtherDevice'),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(discoveryControllerProvider).valueOrNull;
        expect(state?.devices.length, equals(1));
        expect(state?.devices.first.serviceInstanceName, equals('OtherDevice'));
      });
    });

    group('refresh', () {
      test('restarts scan', () async {
        final mockRepository = MockDiscoveryRepository();
        final eventController = StreamController<DiscoveryEvent>.broadcast();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(() {
          eventController.close();
          container.dispose();
        });

        when(
          () => mockRepository.startScan(),
        ).thenAnswer((_) => eventController.stream);
        when(() => mockRepository.stopScan()).thenAnswer((_) async {});

        // Wait for the provider to be ready
        await container.read(discoveryControllerProvider.future);

        final controller = container.read(discoveryControllerProvider.notifier);

        await controller.startScan();
        await controller.refresh();

        verify(() => mockRepository.stopScan()).called(1);
        verify(() => mockRepository.startScan()).called(2);
      });
    });
  });
}
