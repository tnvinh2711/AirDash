import 'package:freezed_annotation/freezed_annotation.dart';

part 'handshake_request.freezed.dart';
part 'handshake_request.g.dart';

/// Request body for handshake endpoint (POST /api/v1/info).
@freezed
class HandshakeRequest with _$HandshakeRequest {
  /// Creates a new [HandshakeRequest] instance.
  const factory HandshakeRequest({
    /// Name of the file being transferred.
    required String fileName,

    /// Size of the file in bytes.
    required int fileSize,

    /// File type/extension (e.g., "pdf", "zip").
    required String fileType,

    /// MD5 checksum for verification.
    required String checksum,

    /// True if transferring a compressed folder.
    required bool isFolder,

    /// Number of files (1 for single file, >1 for folders).
    required int fileCount,

    /// Unique ID of the sending device.
    required String senderDeviceId,

    /// Human-readable name of the sending device.
    required String senderAlias,
  }) = _HandshakeRequest;

  /// Creates a [HandshakeRequest] from JSON.
  factory HandshakeRequest.fromJson(Map<String, dynamic> json) =>
      _$HandshakeRequestFromJson(json);
}
