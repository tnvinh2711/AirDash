# Flux

> **Flux for Every Platform** — Fast, private file transfer over local network

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

Flux is a cross-platform file transfer application that enables fast, private file sharing between devices on the same local network. Unlike cloud-based solutions, Flux transfers files directly between devices (peer-to-peer), ensuring your data never leaves your network and works completely offline.

## Features

- 📱 **Cross-Platform** — Android, iOS, macOS, Windows, Linux from a single codebase
- 🔒 **Privacy First** — Peer-to-peer transfers, no cloud servers or intermediaries
- 📶 **Offline Capable** — Works on LAN/Hotspot without internet connection
- ⚡ **Fast Transfers** — Optimized HTTP-based file transfer for maximum speed
- 🔍 **Auto Discovery** — Automatically find nearby devices using mDNS
- 📁 **Files & Folders** — Transfer individual files or entire directories

## Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported |
| iOS      | ✅ Supported |
| macOS    | ✅ Supported |
| Windows  | ✅ Supported |
| Linux    | ✅ Supported |

## How It Works

Flux uses a simple peer-to-peer architecture for secure, local file transfers:

```
┌─────────────────┐                              ┌─────────────────┐
│   SENDER        │                              │   RECEIVER      │
│                 │                              │                 │
│  1. Select      │      Local Network           │  1. Start       │
│     files       │      (WiFi/Hotspot)          │     server      │
│                 │                              │                 │
│  2. Pick        │  ──────────────────────────► │  2. Broadcast   │
│     device      │      mDNS Discovery          │     presence    │
│                 │                              │                 │
│  3. Send        │  ──────────────────────────► │  3. Accept/     │
│     request     │      HTTP Handshake          │     Reject      │
│                 │                              │                 │
│  4. Transfer    │  ══════════════════════════► │  4. Receive     │
│     files       │      HTTP File Stream        │     & save      │
└─────────────────┘                              └─────────────────┘
```

### Transfer Protocol

1. **Discovery Phase** — Devices broadcast their presence using mDNS (`_flux._tcp` service type). The sender scans for available receivers on the local network.

2. **Handshake Phase** — When the sender selects a device, it sends a handshake request with file metadata (name, size, checksum). The receiver can accept or reject the transfer.

3. **Transfer Phase** — Upon acceptance, files are streamed via HTTP POST with progress tracking. ZIP compression is used for folder transfers.

4. **Verification Phase** — After transfer, checksums are verified to ensure file integrity.

### Key Characteristics

| Aspect | Implementation |
|--------|----------------|
| **Discovery** | mDNS/DNS-SD via Bonsoir package |
| **Transport** | HTTP (Shelf server / Dio client) |
| **Security** | LAN-only, no internet required |
| **Compression** | ZIP for folders, raw stream for files |
| **Integrity** | MD5 checksum verification |

## Prerequisites

- **Flutter SDK** 3.8+ (Dart 3.0+)
- **FVM** (Flutter Version Management) — Recommended for consistent Flutter versions

<details>
<summary>Installing FVM (Recommended)</summary>

```bash
# macOS/Linux
dart pub global activate fvm

# Windows (PowerShell)
dart pub global activate fvm

# Add to PATH (if needed)
export PATH="$PATH:$HOME/.pub-cache/bin"
```

</details>

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/tnvinh2711/AirDash.git
cd AirDash
```

### 2. Install Flutter Version (via FVM)

```bash
fvm install
fvm use
```

### 3. Install Dependencies

```bash
fvm flutter pub get
```

### 4. Generate Code

The project uses code generation for Drift (database), Freezed (immutable classes), and Riverpod (providers).

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

## Running the App

<details>
<summary><strong>macOS</strong></summary>

```bash
fvm flutter run -d macos
```

</details>

<details>
<summary><strong>Windows</strong></summary>

```bash
fvm flutter run -d windows
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
fvm flutter run -d linux
```

</details>

<details>
<summary><strong>iOS</strong></summary>

```bash
# Requires Xcode installed
fvm flutter run -d ios
```

</details>

<details>
<summary><strong>Android</strong></summary>

```bash
# Requires Android Studio / SDK installed
fvm flutter run -d android
```

</details>

## Running Tests

```bash
# Run all tests
fvm flutter test

# Run tests with coverage
fvm flutter test --coverage

# Run a specific test file
fvm flutter test test/path/to/test_file.dart
```

**Coverage Target**: 90% line coverage (per project constitution)

## Project Structure

```
lib/
├── src/
│   ├── core/                   # Shared utilities and infrastructure
│   │   ├── database/           # Drift database setup
│   │   ├── providers/          # Global Riverpod providers
│   │   ├── routing/            # go_router configuration
│   │   └── widgets/            # Reusable UI components
│   │
│   └── features/               # Feature modules (Feature-First)
│       ├── discovery/          # Device discovery (mDNS/Bonsoir)
│       ├── history/            # Transfer history tracking
│       ├── receive/            # File receiving (HTTP server)
│       ├── send/               # File sending (HTTP client)
│       └── settings/           # App settings and preferences
│
├── app.dart                    # Root widget
└── main.dart                   # Entry point
```

Each feature follows **Riverpod Architecture** with these layers:
- `data/` — Repositories and data sources
- `application/` — Business logic (Notifiers/Services)
- `presentation/` — UI widgets and screens
- `domain/` — Data models (Freezed classes)

## Technology Stack

| Category | Library | Purpose |
|----------|---------|---------|
| State Management | `flutter_riverpod` + `riverpod_generator` | Reactive state with code generation |
| Immutability | `freezed` | Immutable data classes |
| Database | `drift` | SQLite abstraction for history/settings |
| Routing | `go_router` | Declarative navigation |
| Theming | `flex_color_scheme` | Material 3 dynamic theming |
| Discovery | `bonsoir` | mDNS device discovery |
| HTTP Server | `shelf` + `shelf_router` | Receive file transfers |
| HTTP Client | `dio` | Send file transfers |
| File Picking | `file_picker` + `desktop_drop` | File/folder selection |

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the architecture patterns in `lib/src/features/`
4. **Write tests** for new functionality (90% coverage target)
5. **Run** `fvm flutter analyze` — must pass with no warnings
6. **Run** `fvm dart format .` — apply consistent formatting
7. **Commit** your changes (`git commit -m 'Add amazing feature'`)
8. **Push** to the branch (`git push origin feature/amazing-feature`)
9. **Open** a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
