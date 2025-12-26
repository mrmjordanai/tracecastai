import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tracecast/app/app.dart';

void main() {
  testWidgets('TraceCast app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TraceCastApp(),
      ),
    );

    // Verify that the app loads with the home screen
    expect(find.text('TraceCast'), findsOneWidget);
  });
}
