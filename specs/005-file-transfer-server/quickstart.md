# Quickstart: File Transfer Server (Receive Logic)

**Feature**: 005-file-transfer-server | **Date**: 2025-12-06

## 1. Install Dependencies

```bash
# Add shelf and shelf_router for HTTP server
fvm flutter pub add shelf shelf_router

# Add crypto for MD5 checksum
fvm flutter pub add crypto

# Add archive for ZIP extraction
fvm flutter pub add archive

# Add uuid for session ID generation
fvm flutter pub add uuid

# Run build_runner for Freezed and Riverpod generators
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

## 2. Platform Configuration

### macOS

Add to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:
```xml
<key>com.apple.security.network.server</key>
<true/>
```

This allows the app to listen for incoming network connections.

### Android

Add to `android/app/src/main/AndroidManifest.xml` (if not already present):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS

No additional configuration required (network server already enabled via Bonjour setup in Spec 04).

## 3. Usage Examples

### Start/Stop Server

```dart
// In a widget
final serverState = ref.watch(serverControllerProvider);
final controller = ref.read(serverControllerProvider.notifier);

// Toggle server
await controller.toggleServer();

// Or explicit start/stop
await controller.startServer();
await controller.stopServer();
```

### Monitor Server State

```dart
Consumer(
  builder: (context, ref, _) {
    final state = ref.watch(serverControllerProvider);
    
    return state.when(
      data: (serverState) {
        if (!serverState.isRunning) {
          return Text('Server stopped');
        }
        
        if (serverState.activeSession != null) {
          final progress = serverState.transferProgress;
          return Column(
            children: [
              Text('Receiving: ${serverState.activeSession!.metadata.fileName}'),
              if (progress != null)
                LinearProgressIndicator(value: progress.percentComplete / 100),
            ],
          );
        }
        
        return Text('Server running on port ${serverState.port}');
      },
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  },
)
```

### Integration with Discovery

The server automatically integrates with Spec 04 Discovery:

```dart
// When server starts:
// 1. HTTP server binds to port
// 2. Discovery broadcast starts with server port
// 3. Other devices can discover and connect

// When server stops:
// 1. Discovery broadcast stops
// 2. HTTP server unbinds
```

## 4. Testing the Server

### Manual Test with curl

```bash
# 1. Start server in app, note the port (e.g., 8080)

# 2. Send handshake
curl -X POST http://localhost:8080/api/v1/info \
  -H "Content-Type: application/json" \
  -d '{
    "fileName": "test.txt",
    "fileSize": 13,
    "fileType": "text/plain",
    "checksum": "d8e8fca2dc0f896fd7cb4cb0031ba249",
    "isFolder": false,
    "fileCount": 1,
    "senderDeviceId": "test-device",
    "senderAlias": "Test Device"
  }'

# Response: {"accepted":true,"sessionId":"<uuid>","serverCapabilities":{...}}

# 3. Upload file
curl -X POST http://localhost:8080/api/v1/upload \
  -H "Content-Type: application/octet-stream" \
  -H "X-Transfer-Session: <sessionId from step 2>" \
  --data-binary "Hello, World!"

# Response: {"success":true,"savedPath":"...","checksumVerified":true}
```

### Generate Test Checksum

```bash
echo -n "Hello, World!" | md5
# Output: d8e8fca2dc0f896fd7cb4cb0031ba249
```

## 5. File Locations

Received files are saved to platform-appropriate Downloads folder:

| Platform | Default Path |
|----------|--------------|
| macOS | `~/Downloads/` |
| Windows | `%USERPROFILE%\Downloads\` |
| Linux | `~/Downloads/` |
| iOS | App Documents directory |
| Android | App external storage / Downloads |

