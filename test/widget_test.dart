import 'package:flutter_test/flutter_test.dart';
import 'package:kipepeo/main.dart';

void main() {
  testWidgets('Phase 1 Simulation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KipepeoApp());

    // Verify that the Simulation Dashboard is displayed.
    expect(find.text('Kipepeo: Phase 1 Simulation'), findsOneWidget);
    expect(find.text('Start Phase 1 Simulation'), findsOneWidget);

    // Verify the initial status.
    expect(find.text('Status: Ready to simulate'), findsOneWidget);
  });
}
