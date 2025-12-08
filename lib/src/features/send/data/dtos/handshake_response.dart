import 'package:freezed_annotation/freezed_annotation.dart';

part 'handshake_response.freezed.dart';
part 'handshake_response.g.dart';

/// Response from handshake endpoint (POST /api/v1/info).
@freezed
class HandshakeResponse with _$HandshakeResponse {
  /// Creates a new [HandshakeResponse] instance.
  const factory HandshakeResponse({
    /// Whether the transfer was accepted.
    required bool accepted,

    /// Session ID for upload (only if accepted).
    String? sessionId,

    /// Error code if rejected (busy, insufficient_storage, invalid_request).
    String? error,
  }) = _HandshakeResponse;

  /// Creates a [HandshakeResponse] from JSON.
  factory HandshakeResponse.fromJson(Map<String, dynamic> json) =>
      _$HandshakeResponseFromJson(json);
}
