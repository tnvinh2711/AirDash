import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/features/send/application/file_selection_controller.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:flux/src/features/settings/application/settings_provider.dart';
import 'package:flux/src/features/settings/data/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Mock SettingsRepository that stores selection
/// as JSON string (matching real API).
class MockSettingsRepository extends Mock implements SettingsRepository {
  String? _selectionQueueJson;

  @override
  Future<String?> getSelectionQueue() async {
    return _selectionQueueJson;
  }

  @override
  Future<void> setSelectionQueue(String jsonString) async {
    _selectionQueueJson = jsonString;
  }
}

void main() {
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  /// Helper to wait for async operations in the controller's build method.
  Future<void> waitForControllerInit() async {
    // Give time for the fire-and-forget _loadPersistedSelection to complete
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  group('FileSelectionController', () {
    test('initial state is empty list', () async {
      // Arrange
      final container = createContainer();
      addTearDown(container.dispose);

      // Act - wait for async load to complete
      await waitForControllerInit();
      final state = container.read(fileSelectionControllerProvider);

      // Assert
      expect(state, isEmpty);
    });

    test('clear removes all items', () async {
      // Arrange
      final container = createContainer();
      addTearDown(container.dispose);

      // Wait for initial build
      await waitForControllerInit();

      // Add some items via pasteText
      container
          .read(fileSelectionControllerProvider.notifier)
          .pasteText('Test');

      // Act
      container.read(fileSelectionControllerProvider.notifier).clear();
      final state = container.read(fileSelectionControllerProvider);

      // Assert
      expect(state, isEmpty);
    });

    group('pasteText', () {
      test('adds text item to selection', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('Hello World');
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, hasLength(1));
        expect(state.first.type, equals(SelectedItemType.text));
        expect(state.first.content, equals('Hello World'));
        expect(state.first.displayName, startsWith('Pasted Text'));
      });

      test('generates unique IDs for multiple text items', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('B');
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, hasLength(2));
        expect(state[0].id, isNot(equals(state[1].id)));
      });

      test('estimates size based on text length', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);
        const text = 'Hello World'; // 11 characters

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText(text);
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        // UTF-8 encoding: 11 bytes for ASCII text
        expect(state.first.sizeEstimate, equals(11));
      });

      test('handles empty text', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('');
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, hasLength(1));
        expect(state.first.content, equals(''));
        expect(state.first.sizeEstimate, equals(0));
      });

      test('handles unicode text', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);
        const text = '你好世界'; // 4 Chinese characters

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText(text);
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state.first.content, equals(text));
        // UTF-8: 3 bytes per Chinese character = 12 bytes
        expect(state.first.sizeEstimate, equals(12));
      });
    });

    group('removeItem', () {
      test('removes item by id', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('B');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('C');
        final items = container.read(fileSelectionControllerProvider);
        final idToRemove = items[1].id;

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .removeItem(idToRemove);
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, hasLength(2));
        expect(state.map((e) => e.content), containsAll(['A', 'C']));
        expect(state.map((e) => e.id), isNot(contains(idToRemove)));
      });

      test('does nothing when id not found', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .removeItem('nonexistent-id');
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, hasLength(1));
      });

      test('removes last item leaving empty list', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');
        final items = container.read(fileSelectionControllerProvider);
        final idToRemove = items.first.id;

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .removeItem(idToRemove);
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state, isEmpty);
      });
    });

    group('multi-item selection', () {
      test('maintains order of added items', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        // Act
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('1');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('2');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('3');
        final state = container.read(fileSelectionControllerProvider);

        // Assert
        expect(state.map((e) => e.content).toList(), equals(['1', '2', '3']));
      });

      test('calculates total size correctly', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('AB'); // 2 bytes
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('CDE'); // 3 bytes

        // Act
        final totalSize =
            container.read(fileSelectionControllerProvider.notifier).totalSize;

        // Assert
        expect(totalSize, equals(5));
      });

      test('count returns correct number of items', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');
        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('B');

        // Act
        final count =
            container.read(fileSelectionControllerProvider.notifier).count;

        // Assert
        expect(count, equals(2));
      });

      test('isEmpty returns true when empty', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        // Act & Assert
        expect(
          container.read(fileSelectionControllerProvider.notifier).isEmpty,
          isTrue,
        );
      });

      test('isEmpty returns false when has items', () async {
        // Arrange
        final container = createContainer();
        addTearDown(container.dispose);

        // Wait for initial build
        await waitForControllerInit();

        container
            .read(fileSelectionControllerProvider.notifier)
            .pasteText('A');

        // Act & Assert
        expect(
          container.read(fileSelectionControllerProvider.notifier).isEmpty,
          isFalse,
        );
      });
    });
  });
}
