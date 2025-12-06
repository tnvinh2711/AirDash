import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/send/application/transfer_controller.dart';
import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:flux/src/features/send/domain/transfer_state.dart';

void main() {
  group('TransferController', () {
    test('initial state is idle', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final state = container.read(transferControllerProvider);

      // Assert
      expect(state, isA<TransferStateIdle>());
    });

    test('reset returns to idle state', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(transferControllerProvider.notifier).reset();
      final state = container.read(transferControllerProvider);

      // Assert
      expect(state, isA<TransferStateIdle>());
    });

    // Note: Full integration tests for send() require mocking
    // CompressionService, TransferClientService, and HistoryRepository.
    // These are covered in integration tests.
  });

  group('TransferController state transitions', () {
    test('state types are correctly defined', () {
      // Verify all state types exist and can be instantiated
      const idle = TransferState.idle();
      expect(idle, isA<TransferStateIdle>());

      final preparing = TransferState.preparing(
        currentItem: _createTestItem(),
      );
      expect(preparing, isA<TransferStatePreparing>());

      final completed = TransferState.completed(results: []);
      expect(completed, isA<TransferStateCompleted>());

      final failed = TransferState.failed(error: 'test', results: []);
      expect(failed, isA<TransferStateFailed>());

      final cancelled = TransferState.cancelled(results: []);
      expect(cancelled, isA<TransferStateCancelled>());

      final partialSuccess = TransferState.partialSuccess(results: []);
      expect(partialSuccess, isA<TransferStatePartialSuccess>());
    });
  });
}

SelectedItem _createTestItem() {
  return const SelectedItem(
    id: 'test-id',
    type: SelectedItemType.file,
    path: '/test/path.txt',
    displayName: 'path.txt',
    sizeEstimate: 1024,
  );
}

Device _createTestDevice() {
  return Device(
    serviceInstanceName: 'test-device._flux._tcp.local',
    ip: '192.168.1.100',
    port: 8080,
    alias: 'Test Device',
    deviceType: DeviceType.desktop,
    os: 'macOS',
    lastSeen: DateTime.now(),
  );
}

