import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_metadata.freezed.dart';
part 'transfer_metadata.g.dart';

/// Metadata about an incoming file transfer from the handshake request.
///
/// This data is sent by the sender in the `POST /api/v1/info` handshake
/// and contains all information needed to prepare for the file upload.
@freezed
class TransferMetadata with _$TransferMetadata {
  /// Creates a new [TransferMetadata] instance.
  const factory TransferMetadata({
    /// Original filename (or folder name).
    required String fileName,

    /// Total size in bytes.
    required int fileSize,

    /// MIME type or extension identifier.
    required String fileType,

    /// MD5 hash of file content for integrity verification.
    required String checksum,

    /// True if this is a ZIP-compressed folder transfer.
    required bool isFolder,

    /// Number of files (1 for single file, >1 for folder).
    required int fileCount,

    /// Sender's service instance name (mDNS identifier).
    required String senderDeviceId,

    /// Sender's human-readable device name.
    required String senderAlias,
  }) = _TransferMetadata;

  const TransferMetadata._();

  /// Creates a [TransferMetadata] from JSON.
  factory TransferMetadata.fromJson(Map<String, dynamic> json) =>
      _$TransferMetadataFromJson(json);

  /// Validates the metadata fields.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  String? validate() {
    if (fileName.isEmpty) {
      return 'fileName is required';
    }
    if (fileSize <= 0) {
      return 'fileSize must be greater than 0';
    }
    if (checksum.isEmpty) {
      return 'checksum is required';
    }
    if (checksum.length != 32) {
      return 'checksum must be a 32-character MD5 hash';
    }
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(checksum)) {
      return 'checksum must be a valid hexadecimal MD5 hash';
    }
    return null;
  }
}
