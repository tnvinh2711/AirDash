# API Contracts: File Transfer Server

**Feature**: 005-file-transfer-server | **Date**: 2025-12-06

## Base URL

Server listens on dynamically assigned port (e.g., `http://<device-ip>:8080`)

---

## POST /api/v1/info

**Purpose**: Handshake - exchange transfer metadata before upload

### Request

**Headers**:
| Header | Value | Required |
|--------|-------|----------|
| Content-Type | application/json | ✅ |

**Body** (JSON):
```json
{
  "fileName": "document.pdf",
  "fileSize": 1048576,
  "fileType": "application/pdf",
  "checksum": "d41d8cd98f00b204e9800998ecf8427e",
  "isFolder": false,
  "fileCount": 1,
  "senderDeviceId": "MacBook-Pro._flux._tcp.local",
  "senderAlias": "John's MacBook"
}
```

### Response

**Success (200 OK)**:
```json
{
  "accepted": true,
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "serverCapabilities": {
    "maxFileSize": null,
    "supportedTypes": ["*"]
  },
  "error": null
}
```

**Busy (409 Conflict)**:
```json
{
  "accepted": false,
  "sessionId": null,
  "serverCapabilities": null,
  "error": "busy"
}
```

**Insufficient Storage (507)**:
```json
{
  "accepted": false,
  "sessionId": null,
  "serverCapabilities": null,
  "error": "insufficient_storage"
}
```

**Bad Request (400)**:
```json
{
  "accepted": false,
  "sessionId": null,
  "serverCapabilities": null,
  "error": "invalid_request: missing required field 'checksum'"
}
```

---

## POST /api/v1/upload

**Purpose**: Stream file data after successful handshake

### Request

**Headers**:
| Header | Value | Required |
|--------|-------|----------|
| Content-Type | application/octet-stream | ✅ |
| X-Transfer-Session | {sessionId from handshake} | ✅ |
| Content-Length | {file size in bytes} | ✅ |

**Body**: Raw binary file data (streamed)

### Response

**Success (200 OK)**:
```json
{
  "success": true,
  "savedPath": "/Users/john/Downloads/document.pdf",
  "checksumVerified": true,
  "error": null
}
```

**Invalid Session (401 Unauthorized)**:
```json
{
  "success": false,
  "savedPath": null,
  "checksumVerified": false,
  "error": "invalid_session"
}
```

**Session Expired (410 Gone)**:
```json
{
  "success": false,
  "savedPath": null,
  "checksumVerified": false,
  "error": "session_expired"
}
```

**Checksum Mismatch (422 Unprocessable Entity)**:
```json
{
  "success": false,
  "savedPath": null,
  "checksumVerified": false,
  "error": "checksum_mismatch"
}
```

**Storage Error (500)**:
```json
{
  "success": false,
  "savedPath": null,
  "checksumVerified": false,
  "error": "storage_error: disk write failed"
}
```

---

## Error Codes Summary

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | invalid_request | Malformed JSON or missing required fields |
| 401 | invalid_session | Session ID not found or invalid |
| 409 | busy | Server already handling another transfer |
| 410 | session_expired | Session timed out (>5 minutes) |
| 422 | checksum_mismatch | File integrity verification failed |
| 500 | storage_error | File system write failure |
| 507 | insufficient_storage | Not enough disk space |

