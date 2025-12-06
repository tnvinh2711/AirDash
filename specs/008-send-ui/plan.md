# Implementation Plan: Send Tab UI

**Branch**: `008-send-ui` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-send-ui/spec.md`

## Summary

Build the Send Tab UI with two main sections: (1) Selection section for adding files/folders/text/media with persistence across sessions and (2) Devices section showing discovered peers in a grid layout. Integrates with existing `FileSelectionController`, `DiscoveryController`, and `TransferController` from features 004 and 006. Primary new work is UI implementation, selection persistence, and desktop drag-and-drop support.

## Technical Context

**Language/Version**: Dart 3.0+ with Sound Null Safety (Flutter Stable via FVM)
**Primary Dependencies**: `flutter_riverpod`, `riverpod_annotation`, `freezed`, `file_picker`, `desktop_drop`, `flex_color_scheme`, `go_router`
**Storage**: Drift (SQLite) via `SettingsRepository` for selection persistence (JSON-serialized list)
**Testing**: `flutter_test`, `mocktail` for mocking providers
**Target Platform**: Android, iOS, macOS, Windows, Linux
**Project Type**: Mobile + Desktop Flutter app
**Performance Goals**: 60fps UI, selection operations <100ms, device list updates <500ms
**Constraints**: Offline-capable (LAN only), persist selection across restarts, warn at 1GB total selection
**Scale/Scope**: Single screen with 2 sections, ~8 widgets, ~4 providers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy First | ✅ Pass | No external servers, peer-to-peer only |
| II. Offline First | ✅ Pass | LAN-only discovery, no internet required |
| III. Universal Access | ✅ Pass | Responsive grid (2-3 cols mobile, 3-4 desktop) |
| IV. High Performance | ✅ Pass | 60fps target, async file operations |
| V. Test-First | ✅ Pass | Unit tests for controller, widget tests for UI |
| Technology Stack | ✅ Pass | Using mandated: Riverpod, Freezed, Drift, flex_color_scheme |
| Architecture | ✅ Pass | Feature-first structure, Application layer logic |
| Quality Gates | ✅ Pass | flutter analyze, dart format, 90% coverage target |

## Project Structure

### Documentation (this feature)

```text
specs/008-send-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A (no API contracts - UI only feature)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/src/features/send/
├── application/
│   ├── file_selection_controller.dart     # EXISTING - add persistence
│   ├── file_selection_controller.g.dart   # EXISTING
│   ├── transfer_controller.dart           # EXISTING - no changes
│   └── transfer_controller.g.dart         # EXISTING
├── data/
│   ├── file_picker_service.dart           # EXISTING - add media picker
│   ├── file_picker_service.g.dart         # EXISTING
│   ├── compression_service.dart           # EXISTING - no changes
│   └── transfer_client_service.dart       # EXISTING - no changes
├── domain/
│   ├── selected_item.dart                 # EXISTING - add JSON serialization
│   ├── selected_item.freezed.dart         # EXISTING
│   └── selected_item_type.dart            # EXISTING - add media type
└── presentation/
    ├── send_screen.dart                   # MODIFY - full implementation
    └── widgets/
        ├── selection_action_buttons.dart  # NEW - File/Folder/Text/Media buttons
        ├── selection_list.dart            # NEW - Selected items with X remove
        ├── selection_item_tile.dart       # NEW - Individual item row
        ├── device_grid.dart               # NEW - Nearby devices grid
        ├── device_grid_item.dart          # NEW - Single device card
        └── drop_zone_overlay.dart         # NEW - Drag & drop feedback (desktop)

lib/src/features/discovery/
├── application/
│   └── discovery_controller.dart          # EXISTING - use refresh()

lib/src/features/settings/
├── data/
│   └── settings_repository.dart           # EXISTING - add selection persistence methods

test/features/send/
├── application/
│   └── file_selection_controller_test.dart  # EXISTING - extend for persistence
└── presentation/
    ├── send_screen_test.dart                # NEW
    └── widgets/
        ├── selection_list_test.dart         # NEW
        └── device_grid_test.dart            # NEW
```

**Structure Decision**: Flutter feature-first architecture. Extends existing `send` feature with new presentation widgets. Uses existing controllers and repositories with minimal modifications.
