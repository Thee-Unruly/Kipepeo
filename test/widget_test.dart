import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kipepeo/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KipepeoApp());

    // Verify that the Dashboard is displayed.
    expect(find.text('Kipepeo Engine'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    // Verify the initial status.
    expect(find.text('Ready to fetch live data'), findsOneWidget);
  });
}
