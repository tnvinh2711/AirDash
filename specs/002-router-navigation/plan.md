# Implementation Plan: Router and Navigation Structure (3 Tabs)

**Branch**: `002-router-navigation` | **Date**: 2025-12-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-router-navigation/spec.md`

## Summary

Implement the core navigation shell for FLUX using `go_router` with `StatefulShellRoute` to provide 3 top-level tabs (Receive, Send, Settings) with state preservation. The navigation UI adapts responsively between `NavigationBar` (mobile < 600px) and `NavigationRail` (desktop ≥ 600px) per constitution requirements.

## Technical Context

**Language/Version**: Dart 3.0+ (Sound Null Safety) via Flutter stable channel (FVM)
**Primary Dependencies**: `go_router` (routing), `flutter_riverpod` (state), `flex_color_scheme` (theming)
**Storage**: N/A (no persistence for this feature)
**Testing**: `flutter_test` with widget tests for navigation switching
**Target Platform**: Android, iOS, macOS, Windows, Linux (all 5 platforms)
**Project Type**: Mobile/Desktop cross-platform Flutter app
**Performance Goals**: 60fps+ UI rendering, <100ms tab switching response
**Constraints**: Offline-capable, single codebase for all platforms
**Scale/Scope**: 3 top-level tabs, responsive breakpoint at 600px

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Requirement | Source | Status | Notes |
|-------------|--------|--------|-------|
| FVM + Flutter stable | Core Framework | ✅ PASS | Already configured in 001-project-init |
| `go_router` for navigation | Navigation & Networking | ✅ PASS | Already in pubspec.yaml |
| `flutter_riverpod` for state | State Management | ✅ PASS | Already in pubspec.yaml |
| `flex_color_scheme` theming | UI & Theming | ✅ PASS | Already in pubspec.yaml |
| Material 3 (`useMaterial3: true`) | UI & Theming | ✅ PASS | Configured in app.dart |
| NavigationBar for mobile (<600dp) | Adaptive Navigation | 🔄 TO IMPLEMENT | This feature |
| NavigationRail for desktop (≥600dp) | Adaptive Navigation | 🔄 TO IMPLEMENT | This feature |
| Fluid transition on resize | Adaptive Navigation | 🔄 TO IMPLEMENT | This feature |
| Widget tests for UI components | Test-First Development | 🔄 TO IMPLEMENT | This feature |
| Zero lints | Quality Gates | ✅ PASS | Maintained from 001 |

**Gate Result**: ✅ PASS - All pre-requisites satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-router-navigation/
├── plan.md              # This file
├── research.md          # Phase 0: go_router patterns research
├── data-model.md        # Phase 1: Route/Tab entity definitions
├── quickstart.md        # Phase 1: Quick implementation guide
├── contracts/           # Phase 1: N/A (no API contracts for this feature)
└── tasks.md             # Phase 2: Implementation tasks (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── core/
│   │   └── routing/
│   │       ├── app_router.dart         # GoRouter configuration with StatefulShellRoute
│   │       └── routes.dart             # Route path constants
│   └── features/
│       ├── receive/
│       │   └── presentation/
│       │       └── receive_screen.dart  # Placeholder screen
│       ├── send/
│       │   └── presentation/
│       │       └── send_screen.dart     # Placeholder screen
│       └── settings/
│           └── presentation/
│               └── settings_screen.dart # Placeholder screen
├── app.dart             # Root widget (update to use router)
└── main.dart            # Entry point with ProviderScope

lib/src/core/
└── widgets/
    └── scaffold_with_nav_bar.dart  # Responsive NavigationBar/NavigationRail

test/
└── widget/
    └── navigation_test.dart         # Widget tests for tab switching
```

**Structure Decision**: Flutter single-project structure following constitution's Riverpod Architecture (Feature-First). Routing logic placed in `core/routing/` as shared infrastructure. Each tab gets a feature folder with placeholder presentation layer.

## Complexity Tracking

> No violations. Design follows constitution patterns exactly.


## Post-Design Constitution Re-Check

| Requirement | Status | Verification |
|-------------|--------|--------------|
| `go_router` for navigation | ✅ COMPLIANT | Used in app_router.dart |
| NavigationBar for mobile | ✅ COMPLIANT | ScaffoldWithNavBar <600px |
| NavigationRail for desktop | ✅ COMPLIANT | ScaffoldWithNavBar ≥600px |
| Fluid resize transition | ✅ COMPLIANT | LayoutBuilder pattern |
| Widget tests | ✅ PLANNED | navigation_test.dart |
| Feature-first structure | ✅ COMPLIANT | features/{receive,send,settings}/ |
| Core shared code | ✅ COMPLIANT | core/routing/, core/widgets/ |

**Post-Design Gate Result**: ✅ PASS - Design fully aligned with constitution.

## Generated Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Implementation Plan | `specs/002-router-navigation/plan.md` | ✅ Complete |
| Research | `specs/002-router-navigation/research.md` | ✅ Complete |
| Data Model | `specs/002-router-navigation/data-model.md` | ✅ Complete |
| Quickstart | `specs/002-router-navigation/quickstart.md` | ✅ Complete |
| Contracts | N/A | Not applicable (no API) |

## Next Steps

Run `/speckit.tasks` to generate the implementation task list.
