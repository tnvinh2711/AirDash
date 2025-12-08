# Research: Router and Navigation Structure (3 Tabs)

**Feature**: 002-router-navigation  
**Date**: 2025-12-05  
**Status**: Complete

## Research Topics

### 1. go_router StatefulShellRoute Pattern

**Decision**: Use `StatefulShellRoute.indexedStack` with 3 branches for tab navigation

**Rationale**:
- `StatefulShellRoute` preserves the state of each branch when switching tabs (required by FR-003)
- `indexedStack` variant keeps all branch navigators in memory, enabling instant tab switching
- Each branch gets its own `Navigator` for nested navigation within tabs
- Built-in support for `NavigationBar` and `NavigationRail` via shell builder

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| Regular `ShellRoute` | Does not preserve state between branches |
| Manual `IndexedStack` + `GoRouter` | More complex, reinvents StatefulShellRoute behavior |
| `AutoRoute` | Not in constitution's approved packages |

**Implementation Pattern**:
```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return ScaffoldWithNavBar(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/receive', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/send', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/settings', ...)]),
  ],
)
```

---

### 2. Responsive Navigation Widget Pattern

**Decision**: Use `LayoutBuilder` with 600px breakpoint to switch between `NavigationBar` and `NavigationRail`

**Rationale**:
- Constitution mandates this exact pattern (Adaptive Navigation section)
- `LayoutBuilder` responds to constraint changes immediately (single frame transition)
- No external packages needed - standard Flutter responsive pattern

**Alternatives Considered**:
| Alternative | Why Rejected |
|-------------|--------------|
| `MediaQuery.of(context).size` | Doesn't respond to container constraints, only screen size |
| `responsive_framework` package | Not in constitution's approved packages |
| Platform detection (`Platform.isAndroid`) | Doesn't account for window resizing on desktop |

**Implementation Pattern**:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(...),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(...),
            Expanded(child: child),
          ],
        ),
      );
    }
  },
)
```

---

### 3. Route Path Constants

**Decision**: Define route paths as static constants in a dedicated `Routes` class

**Rationale**:
- Prevents typos in path strings
- Single source of truth for route definitions
- Easy to reference in tests and deep link handling

**Implementation Pattern**:
```dart
abstract class Routes {
  static const receive = '/receive';
  static const send = '/send';
  static const settings = '/settings';
}
```

---

### 4. Default Route and Redirect Strategy

**Decision**: Set `/receive` as initial location with redirect for unknown paths

**Rationale**:
- FR-002 requires `/receive` as default
- FR-010 requires redirect for unknown paths
- `go_router` supports `initialLocation` and `redirect` callback

**Implementation Pattern**:
```dart
GoRouter(
  initialLocation: Routes.receive,
  redirect: (context, state) {
    final validPaths = [Routes.receive, Routes.send, Routes.settings];
    if (!validPaths.contains(state.matchedLocation)) {
      return Routes.receive;
    }
    return null;
  },
  routes: [...],
)
```

---

### 5. Widget Testing Strategy

**Decision**: Use `pumpWidget` with `ProviderScope` and `MaterialApp.router` for navigation tests

**Rationale**:
- SC-004 requires widget tests for tab switching
- Tests must wrap app with `ProviderScope` (Riverpod requirement)
- `MaterialApp.router` accepts `GoRouter` configuration

**Implementation Pattern**:
```dart
testWidgets('tapping Send tab shows Send screen', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: appRouter),
    ),
  );
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
  expect(find.text('Send Screen'), findsOneWidget);
});
```

---

## Summary

All research topics resolved. No NEEDS CLARIFICATION items remain.

| Topic | Decision | Constitution Aligned |
|-------|----------|---------------------|
| Shell Route | `StatefulShellRoute.indexedStack` | ✅ go_router |
| Responsive Nav | `LayoutBuilder` + 600px breakpoint | ✅ Adaptive Navigation |
| Route Constants | Static `Routes` class | ✅ Best practice |
| Default Route | `/receive` with redirect | ✅ FR-002, FR-010 |
| Widget Testing | `ProviderScope` + `MaterialApp.router` | ✅ Test-First |

