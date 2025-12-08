# AirDash Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-05

## Active Technologies
- Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM) + `go_router` (routing), `flutter_riverpod` (state), `flex_color_scheme` (theming) (002-router-navigation)
- N/A (no persistence for this feature) (002-router-navigation)
- Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM) + `drift`, `drift_dev`, `sqlite3_flutter_libs`, `flutter_riverpod`, `riverpod_generator`, `freezed` (003-local-storage)
- Drift (SQLite abstraction) - local database file (003-local-storage)
- Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM) + `bonsoir` (mDNS), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models) (004-device-discovery)
- N/A (in-memory state only; discovered devices are transient) (004-device-discovery)
- Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM) + `shelf`, `shelf_router` (HTTP server), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models), `archive` (ZIP extraction), `crypto` (checksum) (005-file-transfer-server)
- Drift (via existing `HistoryRepository` for recording transfers), file system (save received files) (005-file-transfer-server)
- Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM) + `dio` (HTTP client), `file_picker` (file/folder selection), `archive` (ZIP compression), `flutter_riverpod` + `riverpod_generator` (state), `freezed` (immutable models), `crypto` (checksum) (006-file-transfer-client)
- Dart 3.0+ (Sound Null Safety) via FVM + flutter_riverpod, riverpod_annotation, freezed, go_router, drift, shared_preferences, bonsoir, flex_color_scheme, device_info_plus (007-receive-ui)
- Drift (SQLite) for TransferHistory; Drift SettingsTable for Receive Mode and Quick Save persistence (007-receive-ui)
- Dart 3.0+ with Sound Null Safety (Flutter Stable via FVM) + `flutter_riverpod`, `riverpod_annotation`, `freezed`, `file_picker`, `desktop_drop`, `flex_color_scheme`, `go_router` (008-send-ui)
- Drift (SQLite) via `SettingsRepository` for selection persistence (JSON-serialized list) (008-send-ui)
- Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM) + `flutter_riverpod`, `riverpod_generator`, `freezed`, `shelf`, `shelf_router`, `archive`, `crypto` (009-server-background-isolate)
- Drift (SQLite) for history; File system for received files (009-server-background-isolate)
- Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel (FVM) + `flutter_riverpod`, `riverpod_generator`, `freezed`, `shelf`, `shelf_router`, `bonsoir`, `drift`, `go_router`, `flex_color_scheme` (010-polish-and-fixes)
- Drift (SQLite) for TransferHistory; File system for received files (010-polish-and-fixes)
- Markdown (documentation only) + N/A (no code dependencies) (011-readme-update)
- Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM) + `flutter_riverpod`, `riverpod_generator`, `bonsoir` (mDNS) (012-device-discovery-fix)
- N/A (in-memory state only for discovery) (012-device-discovery-fix)

- Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel (001-project-init)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel

## Code Style

Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel: Follow standard conventions

## Recent Changes
- 012-device-discovery-fix: Added Dart 3.0+ (Sound Null Safety) via Flutter Stable Channel (FVM) + `flutter_riverpod`, `riverpod_generator`, `bonsoir` (mDNS)
- 011-readme-update: Added Markdown (documentation only) + N/A (no code dependencies)
- 010-polish-and-fixes: Added Dart 3.0+ (Full Sound Null Safety) via Flutter Stable Channel (FVM) + `flutter_riverpod`, `riverpod_generator`, `freezed`, `shelf`, `shelf_router`, `bonsoir`, `drift`, `go_router`, `flex_color_scheme`


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
