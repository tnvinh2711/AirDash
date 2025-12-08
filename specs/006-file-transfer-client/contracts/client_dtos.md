# Client DTOs: File Transfer Client

**Feature**: 006-file-transfer-client | **Date**: 2025-12-06

These DTOs are used by the client to communicate with the File Transfer Server (Spec 005).
The server API is already defined in `specs/005-file-transfer-server/contracts/api_endpoints.md`.

## Handshake Request DTO

**Endpoint**: `POST /api/v1/info`

```dart
/// Request body for handshake endpoint.
@freezed
class HandshakeRequest with _$HandshakeRequest {
  const factory HandshakeRequest({
    required String fileName,
    required int fileSize,
    required String fileType,
    required String checksum,
    required bool isFolder,
    required int fileCount,
    required String senderDeviceId,
    required String senderAlias,
  }) = _HandshakeRequest;

  factory HandshakeRequest.fromJson(Map<String, dynamic> json) =>
      _$HandshakeRequestFromJson(json);
}
```

---

## Handshake Response DTO

**Endpoint**: `POST /api/v1/info` (Response)

```dart
/// Response from handshake endpoint.
@freezed
class HandshakeResponse with _$HandshakeResponse {
  const factory HandshakeResponse({
    required bool accepted,
    String? sessionId,
    String? error,
  }) = _HandshakeResponse;

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) =>
      _$HandshakeResponseFromJson(json);
}
```

**Error Values**:
| Value | HTTP Status | Description |
|-------|-------------|-------------|
| `busy` | 409 | Server handling another transfer |
| `insufficient_storage` | 507 | Not enough disk space |
| `invalid_request` | 400 | Malformed request |

---

## Upload Response DTO

**Endpoint**: `POST /api/v1/upload` (Response)

```dart
/// Response from upload endpoint.
@freezed
class UploadResponse with _$UploadResponse {
  const factory UploadResponse({
    required bool success,
    String? savedPath,
    @Default(false) bool checksumVerified,
    String? error,
  }) = _UploadResponse;

  factory UploadResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseFromJson(json);
}
```

**Error Values**:
| Value | HTTP Status | Description |
|-------|-------------|-------------|
| `invalid_session` | 401 | Session ID not found |
| `session_expired` | 410 | Session timed out |
| `checksum_mismatch` | 422 | File integrity failed |
| `storage_error` | 500 | Write failed |

---

## File Location

These DTOs should be created in:
```
lib/src/features/send/data/dtos/
├── handshake_request.dart
├── handshake_response.dart
└── upload_response.dart
```

Or consolidated in:
```
lib/src/features/send/data/transfer_dtos.dart
```

