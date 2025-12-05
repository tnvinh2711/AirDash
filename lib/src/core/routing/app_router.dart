import 'package:flux/src/core/routing/routes.dart';
import 'package:flux/src/core/widgets/scaffold_with_nav_bar.dart';
import 'package:flux/src/features/receive/presentation/receive_screen.dart';
import 'package:flux/src/features/send/presentation/send_screen.dart';
import 'package:flux/src/features/settings/presentation/settings_screen.dart';
import 'package:go_router/go_router.dart';

/// The main router configuration for the FLUX application.
///
/// Uses [StatefulShellRoute.indexedStack] to maintain state across
/// the three main tabs: Receive, Send, and Settings.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.receive,
  redirect: (context, state) {
    // Redirect unknown paths to the default receive route
    final validPaths = [Routes.receive, Routes.send, Routes.settings];
    if (!validPaths.contains(state.matchedLocation)) {
      return Routes.receive;
    }
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Receive tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.receive,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ReceiveScreen(),
              ),
            ),
          ],
        ),
        // Branch 1: Send tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.send,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SendScreen(),
              ),
            ),
          ],
        ),
        // Branch 2: Settings tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
