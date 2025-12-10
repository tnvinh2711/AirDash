import 'package:drift/drift.dart';
import 'package:flux/src/core/database/app_database.dart';
import 'package:flux/src/features/history/domain/new_transfer_history_entry.dart';
import 'package:flux/src/features/history/domain/transfer_history_entry.dart';

/// Repository for managing transfer history persistence.
///
/// Provides methods to add history entries and watch all history as a
/// live stream. History entries are ordered by timestamp (newest first).
class HistoryRepository {
  /// Creates a [HistoryRepository] with the given [AppDatabase].
  HistoryRepository(this._db);

  final AppDatabase _db;

  // ============================================================
  // Write Operations
  // ============================================================

  /// Adds a new transfer history entry.
  ///
  /// The entry will be assigned an auto-incremented `id` and the current
  /// `timestamp` automatically.
  ///
  /// Returns the generated `id` of the new entry.
  Future<int> addEntry(NewTransferHistoryEntry entry) async {
    final companion = TransferHistoryTableCompanion.insert(
      transferId: entry.transferId,
      fileName: entry.fileName,
      fileCount: Value(entry.fileCount),
      totalSize: entry.totalSize,
      fileType: entry.fileType,
      timestamp: DateTime.now(),
      status: entry.status,
      direction: entry.direction,
      remoteDeviceAlias: entry.remoteDeviceAlias,
      savedPath: Value(entry.savedPath),
    );

    return _db.into(_db.transferHistoryTable).insert(companion);
  }

  // ============================================================
  // Read Operations (to be implemented in Phase 5)
  // ============================================================

  /// Watches all transfer history entries as a live-updating stream.
  ///
  /// Entries are ordered by timestamp (newest first).
  /// The stream emits a new list whenever the history changes.
  Stream<List<TransferHistoryEntry>> watchAllEntries() {
    final query = _db.select(_db.transferHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    return query.watch().map((rows) => rows.map(_mapToEntry).toList());
  }

  /// Gets all transfer history entries (one-time read).
  ///
  /// Entries are ordered by timestamp (newest first).
  Future<List<TransferHistoryEntry>> getAllEntries() async {
    final query = _db.select(_db.transferHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    final rows = await query.get();
    return rows.map(_mapToEntry).toList();
  }

  /// Gets a single history entry by its ID.
  ///
  /// Returns `null` if no entry exists with the given ID.
  Future<TransferHistoryEntry?> getEntryById(int id) async {
    final query = _db.select(_db.transferHistoryTable)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntry(row) : null;
  }

  /// Maps a database row to a domain model.
  TransferHistoryEntry _mapToEntry(TransferHistoryEntryData row) {
    return TransferHistoryEntry(
      id: row.id,
      transferId: row.transferId,
      fileName: row.fileName,
      fileCount: row.fileCount,
      totalSize: row.totalSize,
      fileType: row.fileType,
      timestamp: row.timestamp,
      status: row.status,
      direction: row.direction,
      remoteDeviceAlias: row.remoteDeviceAlias,
      savedPath: row.savedPath,
    );
  }
}
