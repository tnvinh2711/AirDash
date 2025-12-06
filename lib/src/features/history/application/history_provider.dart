import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/database_provider.dart';
import 'package:flux/src/features/history/data/history_repository.dart';
import 'package:flux/src/features/history/domain/transfer_history_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_provider.g.dart';

/// Provides the [HistoryRepository] instance.
///
/// The repository is lazily initialized and persists for the lifetime
/// of the application.
@Riverpod(keepAlive: true)
HistoryRepository historyRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return HistoryRepository(db);
}

/// Provides a live-updating stream of all transfer history entries.
///
/// Entries are ordered by timestamp (newest first).
/// The stream emits a new list whenever the history changes.
@riverpod
Stream<List<TransferHistoryEntry>> historyStream(Ref ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.watchAllEntries();
}

/// Provides a single history entry by ID.
///
/// Returns `null` if no entry exists with the given ID.
@riverpod
Future<TransferHistoryEntry?> historyEntry(Ref ref, int id) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getEntryById(id);
}
