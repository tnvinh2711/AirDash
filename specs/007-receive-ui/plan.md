# Implementation Plan: Receive Tab UI

**Branch**: `007-receive-ui` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-receive-ui/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build the Receive Tab UI with Identity Card (avatar, alias, IP, port), Server Control toggle (Receive Mode with pulse animation), Quick Save switch, and full-screen HistoryView. Leverages existing `ServerController`, `DeviceInfoProvider`, `HistoryRepository`, and `DiscoveryController` from prior features. Adds IP address retrieval, settings persistence for Receive Mode and Quick Save, and new UI widgets.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via FVM
**Primary Dependencies**: flutter_riverpod, riverpod_annotation, freezed, go_router, drift, shared_preferences, bonsoir, flex_color_scheme, device_info_plus
**Storage**: Drift (SQLite) for TransferHistory; Drift SettingsTable for Receive Mode and Quick Save persistence
**Testing**: flutter_test with widget tests and unit tests
**Target Platform**: Android, iOS, Windows, macOS, Linux
**Project Type**: Mobile/Desktop Flutter app (feature-first structure)
**Performance Goals**: 60fps UI, <1s load times (SC-001, SC-006), <500ms toggle response (SC-003)
**Constraints**: Offline-capable (LAN only), must work without internet
**Scale/Scope**: Single Receive tab with ~5 widgets, 1 new route (HistoryView)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Rule | Status | Notes |
|------|--------|-------|
| **Dart 3.0+ Sound Null Safety** | ✅ Pass | Using FVM with stable channel |
| **Riverpod Architecture (Pragmatic)** | ✅ Pass | Using flutter_riverpod + riverpod_annotation |
| **Feature-First Structure** | ✅ Pass | Code in `lib/src/features/receive/` |
| **No "Use Cases"** | ✅ Pass | Direct repository usage from controllers |
| **freezed for Domain Models** | ✅ Pass | Using freezed for immutable data classes |
| **go_router for Navigation** | ✅ Pass | Adding `/history` route to existing router |
| **Material 3 + flex_color_scheme** | ✅ Pass | Using existing theme infrastructure |
| **Testing Strategy** | ✅ Pass | Widget tests + unit tests planned |
| **Zero Lints** | ✅ Pass | Will run `flutter analyze` |
| **Max 3 Projects** | ✅ Pass | Single Flutter project |
| **Direct Repository Usage** | ✅ Pass | Controllers access repositories directly |

## Project Structure

### Documentation (this feature)

```text
specs/007-receive-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (if applicable)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/src/
├── core/
│   ├── providers/
│   │   └── device_info_provider.dart  # Extend with IP address retrieval
│   ├── routing/
│   │   ├── app_router.dart            # Add /history route
│   │   └── routes.dart                # Add history route constant
│   └── database/
│       └── tables/settings_table.dart # Existing (reuse for Receive Mode, Quick Save)
├── features/
│   ├── receive/
│   │   ├── application/
│   │   │   ├── server_controller.dart # Existing (extend for state persistence)
│   │   │   └── receive_settings_provider.dart # NEW: Receive Mode + Quick Save
│   │   ├── domain/
│   │   │   └── receive_settings.dart  # NEW: Settings model
│   │   └── presentation/
│   │       ├── receive_screen.dart    # MODIFY: New layout with Identity Card
│   │       ├── widgets/
│   │       │   ├── identity_card.dart # NEW: Avatar, alias, IP, port
│   │       │   ├── server_toggle.dart # NEW: Receive Mode toggle
│   │       │   └── quick_save_switch.dart # NEW: Quick Save toggle
│   │       └── history_screen.dart    # NEW: Full-screen history view
│   ├── history/
│   │   └── application/
│   │       └── history_provider.dart  # Existing (reuse)
│   └── settings/
│       └── data/
│           └── settings_repository.dart # Extend with Receive Mode, Quick Save keys

test/
├── features/
│   └── receive/
│       ├── application/
│       │   └── receive_settings_provider_test.dart
│       └── presentation/
│           ├── receive_screen_test.dart
│           ├── identity_card_test.dart
│           └── history_screen_test.dart
```

**Structure Decision**: Feature-first Flutter structure following FLUX Constitution. All receive-related code in `lib/src/features/receive/`. Reuses existing infrastructure from features 003 (local-storage), 004 (device-discovery), and 005 (file-server).

## Complexity Tracking

> No violations - all Constitution rules pass.
