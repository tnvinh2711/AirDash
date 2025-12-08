# Quickstart: Router and Navigation Structure (3 Tabs)

**Feature**: 002-router-navigation  
**Date**: 2025-12-05

## Prerequisites

- ✅ Flutter project initialized (001-project-init complete)
- ✅ `go_router` in pubspec.yaml
- ✅ `flutter_riverpod` in pubspec.yaml
- ✅ `flex_color_scheme` configured

## File Creation Order

### 1. Route Constants (`lib/src/core/routing/routes.dart`)

```dart
abstract class Routes {
  static const receive = '/receive';
  static const send = '/send';
  static const settings = '/settings';
}
```

### 2. Placeholder Screens (3 files)

Create minimal screens in each feature folder:
- `lib/src/features/receive/presentation/receive_screen.dart`
- `lib/src/features/send/presentation/send_screen.dart`
- `lib/src/features/settings/presentation/settings_screen.dart`

Each screen: simple `Scaffold` with centered `Text` showing tab name.

### 3. ScaffoldWithNavBar (`lib/src/core/widgets/scaffold_with_nav_bar.dart`)

```dart
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  
  // Use LayoutBuilder with 600px breakpoint
  // < 600: Scaffold with bottomNavigationBar: NavigationBar
  // >= 600: Scaffold with Row(NavigationRail, Expanded(child))
}
```

### 4. App Router (`lib/src/core/routing/app_router.dart`)

```dart
final appRouter = GoRouter(
  initialLocation: Routes.receive,
  redirect: _guardUnknownRoutes,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        // Branch 0: Receive
        // Branch 1: Send  
        // Branch 2: Settings
      ],
    ),
  ],
);
```

### 5. Update app.dart

Replace `MaterialApp` with `MaterialApp.router`:
```dart
MaterialApp.router(
  routerConfig: appRouter,
  theme: FlexThemeData.light(...),
  darkTheme: FlexThemeData.dark(...),
)
```

### 6. Widget Test (`test/widget/navigation_test.dart`)

Test cases:
1. Default route shows Receive tab
2. Tapping Send shows Send screen
3. Tapping Settings shows Settings screen
4. Tab state preserved when switching

## Verification Commands

```bash
# Format and analyze
fvm dart format .
fvm flutter analyze

# Run tests
fvm flutter test

# Run on macOS (desktop)
fvm flutter run -d macos

# Resize window to verify responsive navigation
```

## Success Criteria Verification

| Criteria | How to Verify |
|----------|---------------|
| SC-001: <100ms tab switch | Manual test - no perceptible delay |
| SC-002: State preserved | Navigate away and back, scroll position maintained |
| SC-003: Single-frame layout | Resize window rapidly across 600px |
| SC-004: Widget tests pass | `fvm flutter test` returns all green |
| SC-005: 48x48 touch targets | Use Flutter DevTools to measure |

## Common Issues

| Issue | Solution |
|-------|----------|
| `go_router` not found | Run `fvm flutter pub get` |
| Blank screen on launch | Check `initialLocation` matches a valid route |
| Navigation not switching | Ensure `navigationShell.goBranch(index)` called on tap |
| NavigationRail not showing | Check `LayoutBuilder` constraints, not `MediaQuery` |

