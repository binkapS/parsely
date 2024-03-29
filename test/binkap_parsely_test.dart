import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:binkap_parsely/src/parsely.dart';

void main() {
  testWidgets('Parsely widget renders text with gesture recognizers',
      (WidgetTester tester) async {
    // Build the Parsely widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Parsely(
            text: 'Example text with a link https://www.example.com',
            onTap: (element) {
              // Your onTap callback logic here
            },
          ),
        ),
      ),
    );

    // Find the RichText widget
    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsOneWidget);

    // Find the TextSpan widget inside RichText
    final textSpanFinder = find.byType(TextSpan);
    expect(textSpanFinder, findsOneWidget);

    // Find the GestureDetector widgets inside RichText
    final gestureDetectorFinder = find.byType(GestureDetector);
    expect(gestureDetectorFinder, findsWidgets);

    // You can add more specific tests here to ensure that the correct
    // gestures are attached to the appropriate elements based on your onTap callback
  });
}
