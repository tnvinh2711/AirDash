import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/src/core/routing/app_router.dart';

/// Helper function to create a test app with the router.
Widget createTestApp() {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: appRouter,
      theme: FlexThemeData.light(scheme: FlexScheme.blueWhale),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.blueWhale),
    ),
  );
}

void main() {
  // Reset router to initial location before each test
  setUp(() {
    appRouter.go('/receive');
  });

  group('Tab Navigation', () {
    // T007: Test default route shows Receive tab
    testWidgets('default route shows Receive tab', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Receive tab content is displayed
      expect(find.text('Receive'), findsWidgets);
    });

    // T008: Test tapping Send tab shows Send screen
    testWidgets('tapping Send tab shows Send screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Send tab
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Verify Send screen content is displayed
      expect(find.text('Send Screen'), findsOneWidget);
    });

    // T009: Test tapping Settings tab shows Settings screen
    testWidgets('tapping Settings tab shows Settings screen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify Settings screen content is displayed
      expect(find.text('Settings Screen'), findsOneWidget);
    });
  });

  group('Responsive Navigation', () {
    // T018: Test narrow screen shows NavigationBar
    testWidgets('narrow screen shows NavigationBar', (tester) async {
      // Set a narrow screen size (mobile)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify NavigationBar is displayed (bottom navigation)
      expect(find.byType(NavigationBar), findsOneWidget);
      // Verify NavigationRail is NOT displayed
      expect(find.byType(NavigationRail), findsNothing);

      // Reset the view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // T019: Test wide screen shows NavigationRail
    testWidgets('wide screen shows NavigationRail', (tester) async {
      // Set a wide screen size (desktop)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify NavigationRail is displayed (side navigation)
      expect(find.byType(NavigationRail), findsOneWidget);
      // Verify NavigationBar is NOT displayed
      expect(find.byType(NavigationBar), findsNothing);

      // Reset the view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Deep Link Navigation', () {
    // T024: Test navigating to /send path shows Send tab
    testWidgets('navigating to /send path shows Send tab', (tester) async {
      // Navigate directly to /send
      appRouter.go('/send');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Send screen content is displayed
      expect(find.text('Send Screen'), findsOneWidget);
    });

    // T025: Test unknown path redirects to /receive
    testWidgets('unknown path redirects to /receive', (tester) async {
      // Navigate to an unknown path
      appRouter.go('/unknown-path');

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Receive screen is displayed (redirect from unknown path)
      expect(find.text('Receive Screen'), findsOneWidget);
    });
  });
}
