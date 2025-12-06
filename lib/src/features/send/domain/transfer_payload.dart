import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_payload.freezed.dart';

/// Prepared data ready for transfer (after compression/checksum).
@freezed
class TransferPayload with _$TransferPayload {
  /// Creates a new [TransferPayload] instance.
  const factory TransferPayload({
    /// Original selection reference.
    required SelectedItem selectedItem,

    /// Path to file to upload (may be temp ZIP).
    required String sourcePath,

    /// Filename for receiver.
    required String fileName,

    /// Size in bytes.
    required int fileSize,

    /// MIME type or extension.
    required String fileType,

    /// MD5 hash of the file.
    required String checksum,

    /// True if this is a compressed folder.
    required bool isFolder,

    /// Number of files (1 for single file/text, >1 for folders).
    required int fileCount,

    /// True if sourcePath is a temp file that needs cleanup.
    required bool isTempFile,
  }) = _TransferPayload;
}
