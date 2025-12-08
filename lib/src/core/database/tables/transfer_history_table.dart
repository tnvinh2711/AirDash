import 'package:drift/drift.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';

/// Type converter for [TransferStatus] enum to store as integer in SQLite.
class TransferStatusConverter extends TypeConverter<TransferStatus, int> {
  /// Creates a [TransferStatusConverter].
  const TransferStatusConverter();

  @override
  TransferStatus fromSql(int fromDb) => TransferStatus.values[fromDb];

  @override
  int toSql(TransferStatus value) => value.index;
}

/// Type converter for [TransferDirection] enum to store as integer in SQLite.
class TransferDirectionConverter extends TypeConverter<TransferDirection, int> {
  /// Creates a [TransferDirectionConverter].
  const TransferDirectionConverter();

  @override
  TransferDirection fromSql(int fromDb) => TransferDirection.values[fromDb];

  @override
  int toSql(TransferDirection value) => value.index;
}

/// Drift table definition for transfer history entries.
///
/// Records completed, failed, or cancelled file transfers.
@DataClassName('TransferHistoryEntryData')
class TransferHistoryTable extends Table {
  /// Auto-incremented unique record identifier.
  IntColumn get id => integer().autoIncrement()();

  /// UUID identifying the transfer session.
  TextColumn get transferId => text()();

  /// Name of transferred file/folder.
  TextColumn get fileName => text()();

  /// Number of files (>1 for folders).
  IntColumn get fileCount => integer().withDefault(const Constant(1))();

  /// Total size in bytes.
  IntColumn get totalSize => integer()();

  /// File type identifier (e.g., "pdf", "image", "folder").
  TextColumn get fileType => text()();

  /// When transfer completed/failed.
  DateTimeColumn get timestamp => dateTime()();

  /// Completion status (completed, failed, cancelled).
  IntColumn get status => integer().map(const TransferStatusConverter())();

  /// Whether sent or received.
  IntColumn get direction =>
      integer().map(const TransferDirectionConverter())();

  /// Name of the other device.
  TextColumn get remoteDeviceAlias => text()();
}
