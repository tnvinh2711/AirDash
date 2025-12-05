# Quickstart: FLUX Project Setup

**Feature**: 001-project-init
**Date**: 2025-12-05

## Prerequisites

Before starting, ensure you have:

1. **FVM installed** - [Install FVM](https://fvm.app/documentation/getting-started/installation)
   ```bash
   dart pub global activate fvm
   ```

2. **Platform SDKs** (for respective platforms):
   - Android: Android Studio with SDK
   - iOS/macOS: Xcode with command line tools
   - Windows: Visual Studio with C++ workload
   - Linux: Required packages (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`)

## Quick Setup (5 minutes)

### 1. Clone and Enter Project

```bash
git clone <repository-url>
cd flux
```

### 2. Install Flutter via FVM

```bash
fvm install stable
fvm use stable
```

### 3. Install Dependencies

```bash
fvm flutter pub get
```

### 4. Verify Setup

```bash
# Check Flutter installation
fvm flutter doctor

# Run static analysis (should pass with zero warnings)
fvm flutter analyze

# Run tests
fvm flutter test
```

### 5. Run the App

Choose your target platform:

```bash
# macOS (fastest for development)
fvm flutter run -d macos

# Windows
fvm flutter run -d windows

# Linux
fvm flutter run -d linux

# Android (requires emulator or device)
fvm flutter run -d android

# iOS (requires simulator or device, macOS only)
fvm flutter run -d ios
```

## Project Structure

```
lib/
├── src/
│   ├── core/           # Shared utilities, extensions, common widgets
│   └── features/       # Feature modules (add new features here)
├── app.dart            # Root widget
└── main.dart           # Entry point

test/                   # Test files mirror lib/ structure
```

## Code Generation

After modifying `@freezed` or `@riverpod` annotated classes:

```bash
# One-time generation
fvm flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (continuous)
fvm flutter pub run build_runner watch --delete-conflicting-outputs
```

## Common Commands

| Command | Description |
|---------|-------------|
| `fvm flutter pub get` | Install/update dependencies |
| `fvm flutter analyze` | Run static analysis |
| `fvm flutter test` | Run all tests |
| `fvm flutter run` | Run app (debug mode) |
| `fvm flutter build <platform>` | Build release |
| `dart format .` | Format all Dart code |

## Troubleshooting

### FVM not found
```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Platform not enabled
```bash
fvm flutter create --platforms=macos,windows,linux .
```

### Dependency conflicts
```bash
fvm flutter pub cache clean
fvm flutter pub get
```

## Next Steps

1. Run `fvm flutter doctor` to verify all platforms are ready
2. Run `fvm flutter run -d macos` (or your preferred platform)
3. Start building features in `lib/src/features/`

---

*Generated for FLUX project initialization - see [spec.md](./spec.md) for requirements*

