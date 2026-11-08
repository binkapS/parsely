import 'package:binkap_parsely/binkap_parsely.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden (pixel) tests for [Parsely] rendering.
///
/// These are pixel-regression images (under `flutter test` they render with
/// the test-font glyph outlines — enough to catch layout/style drift, not
/// meant to be read). The pub.dev / README screenshots in `screenshots/`
/// are rendered separately from the live `example/` app on the web with
/// real fonts — see `example/lib/screenshot_main.dart`.
///
/// Keep deterministic: default fonts only, fixed viewport via
/// `tester.view`, no animations.
///
/// Regenerate with: `flutter test --update-goldens`
void main() {
  /// Renders [child] inside a fixed-size Material card and compares to the
  /// golden at `goldens/<name>.png`.
  Future<void> pumpGolden(
    WidgetTester tester, {
    required Widget child,
    required String name,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: brightness,
          ),
        ),
        home: Scaffold(
          body: Center(
            child: Container(
              width: 640,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  group('Parsely goldens', () {
    testWidgets('entities default', (tester) async {
      await pumpGolden(
        tester,
        name: 'entities_default',
        child: Parsely(
          text: 'Visit https://binkap.com, email a@b.com, '
              'call +2348068989116, use #flutter and @dartlang.',
          style: const TextStyle(fontSize: 18, height: 1.4),
          onTap: (_) {},
        ),
      );
    });

    testWidgets('entities per-type styles', (tester) async {
      await pumpGolden(
        tester,
        name: 'entities_per_type',
        child: Parsely(
          text: 'Visit https://binkap.com, email a@b.com, '
              'call +2348068989116, use #flutter and @dartlang.',
          style: const TextStyle(fontSize: 18, height: 1.4),
          parsedStyles: const {
            ParselyType.link: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            ParselyType.email: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
            ParselyType.phone: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
            ParselyType.hashTag: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
            ParselyType.mentionTag: TextStyle(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          },
          onTap: (_) {},
        ),
      );
    });

    testWidgets('masked display', (tester) async {
      await pumpGolden(
        tester,
        name: 'masked_display',
        child: Parsely(
          text: 'Call +2348068989116 or mail a@b.com.',
          style: const TextStyle(fontSize: 18, height: 1.4),
          masks: const ParselyMasks(exact: {
            '+2348068989116': 'My Contact',
            'a@b.com': 'hidden@example.com',
          }),
          onTap: (_) {},
        ),
      );
    });

    testWidgets('RTL and unicode hashtags', (tester) async {
      await pumpGolden(
        tester,
        name: 'rtl_unicode',
        child: Parsely(
          text: 'مرحبا @dartlang زر https://binkap.com #مرحبا #100DaysOfCode',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 18, height: 1.4),
          onTap: (_) {},
        ),
      );
    });

    testWidgets('entities in dark theme', (tester) async {
      await pumpGolden(
        tester,
        name: 'entities_dark',
        brightness: Brightness.dark,
        child: Parsely(
          text: 'Visit https://binkap.com, email a@b.com, use #flutter.',
          style: const TextStyle(fontSize: 18, height: 1.4),
          onTap: (_) {},
        ),
      );
    });
  });
}
