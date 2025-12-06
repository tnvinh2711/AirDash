import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_response.freezed.dart';
part 'upload_response.g.dart';

/// Response from upload endpoint (POST /api/v1/upload).
@freezed
class UploadResponse with _$UploadResponse {
  /// Creates a new [UploadResponse] instance.
  const factory UploadResponse({
    /// Whether the upload succeeded.
    required bool success,

    /// Path where file was saved on receiver.
    String? savedPath,

    /// Whether checksum was verified.
    @Default(false) bool checksumVerified,

    /// Error code if failed (invalid_session, session_expired,
    /// checksum_mismatch, storage_error).
    String? error,
  }) = _UploadResponse;

  /// Creates an [UploadResponse] from JSON.
  factory UploadResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseFromJson(json);
}
