import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/app.dart';

void main() {
  testWidgets('FluxApp renders correctly with navigation', (tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FluxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the navigation bar is displayed with all 3 tabs.
    expect(find.text('Receive'), findsWidgets);
    expect(find.text('Send'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify that the default Receive screen is displayed.
    expect(find.text('Receive Screen'), findsOneWidget);
  });
}
