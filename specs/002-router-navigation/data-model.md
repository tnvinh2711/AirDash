# Data Model: Router and Navigation Structure (3 Tabs)

**Feature**: 002-router-navigation  
**Date**: 2025-12-05

## Overview

This feature does not require persistent data entities. The navigation structure is purely UI-based with routing state managed by `go_router`.

## Entities

### NavigationDestination (UI Configuration)

Represents a tab destination in the navigation UI.

| Attribute | Type | Description |
|-----------|------|-------------|
| `path` | `String` | URL path segment (e.g., `/receive`) |
| `label` | `String` | Display text (e.g., "Receive") |
| `icon` | `IconData` | Unselected state icon |
| `selectedIcon` | `IconData` | Selected state icon |
| `index` | `int` | Position in navigation (0-2) |

**Values**:

| Index | Path | Label | Icon | Selected Icon |
|-------|------|-------|------|---------------|
| 0 | `/receive` | Receive | `Icons.download_outlined` | `Icons.download` |
| 1 | `/send` | Send | `Icons.upload_outlined` | `Icons.upload` |
| 2 | `/settings` | Settings | `Icons.settings_outlined` | `Icons.settings` |

### Route State (Runtime)

Managed by `go_router`. No custom state class needed.

| Attribute | Type | Description |
|-----------|------|-------------|
| `currentIndex` | `int` | Active tab index (from `StatefulNavigationShell`) |
| `matchedLocation` | `String` | Current URL path |

## Relationships

```
┌─────────────────────────────────────────────────────────┐
│                    StatefulShellRoute                    │
│                    (indexedStack)                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │  Branch 0   │  │  Branch 1   │  │    Branch 2     │  │
│  │  /receive   │  │   /send     │  │   /settings     │  │
│  │             │  │             │  │                 │  │
│  │ ReceiveScreen│ │ SendScreen  │  │ SettingsScreen  │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              ScaffoldWithNavBar                          │
│  ┌────────────────────┐  ┌────────────────────────────┐ │
│  │ < 600px            │  │ ≥ 600px                    │ │
│  │ NavigationBar      │  │ NavigationRail + Content   │ │
│  │ (bottom)           │  │ (left side)                │ │
│  └────────────────────┘  └────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## State Transitions

This feature has no complex state machine. Navigation is handled by `go_router`:

1. **App Launch** → Initial route: `/receive` (index 0)
2. **Tab Tap** → `navigationShell.goBranch(index)` → Route changes
3. **Deep Link** → `go_router` resolves path → Correct tab selected
4. **Invalid Path** → Redirect → `/receive`

## Validation Rules

| Rule | Enforcement |
|------|-------------|
| Valid paths only | Redirect unknown paths to `/receive` |
| Index bounds | go_router enforces 0-2 branch index |
| Non-null icons | Compile-time (IconData is non-nullable) |

## Notes

- No database/persistence needed for this feature
- No Freezed classes needed (no complex domain entities)
- Route state is ephemeral (lost on app restart, which is expected for navigation)

