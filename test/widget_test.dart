import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/app.dart';

void main() {
  testWidgets('FluxApp renders correctly', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FluxApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('FLUX'), findsWidgets);

    // Verify that the subtitle is displayed.
    expect(find.text('Peer-to-Peer File Sharing'), findsOneWidget);
  });
}
