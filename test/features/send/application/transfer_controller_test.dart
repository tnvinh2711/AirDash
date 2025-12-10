import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

      final preparing = TransferState.preparing(currentItem: _createTestItem());
      expect(preparing, isA<TransferStatePreparing>());

      const completed = TransferState.completed(
        results: [],
        targetDeviceAlias: 'test-device',
      );
      expect(completed, isA<TransferStateCompleted>());

      const failed = TransferState.failed(
        error: 'test',
        results: [],
        targetDeviceAlias: 'test-device',
      );
      expect(failed, isA<TransferStateFailed>());

      const cancelled = TransferState.cancelled(
        results: [],
        targetDeviceAlias: 'test-device',
      );
      expect(cancelled, isA<TransferStateCancelled>());

      const partialSuccess = TransferState.partialSuccess(
        results: [],
        targetDeviceAlias: 'test-device',
      );
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
