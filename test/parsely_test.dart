import 'package:binkap_parsely/binkap_parsely.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Unwrap the [TextSpan] children built by [Parsely].
  List<TextSpan> spans(WidgetTester tester) {
    final richText = tester.widget<RichText>(find.byType(RichText));
    return (richText.text as TextSpan).children!.cast<TextSpan>();
  }

  List<TextSpan> selectableSpans(WidgetTester tester) {
    final st = tester.widget<SelectableText>(find.byType(SelectableText));
    return (st.textSpan as TextSpan).children!.cast<TextSpan>();
  }

  String rebuilt(List<TextSpan> xs) => xs.map((s) => s.text ?? '').join();

  Future<void> pumpParsely(
    WidgetTester tester, {
    required String text,
    ParselyOptions? options,
    ValueChanged<ParselyElement>? onTap,
    TextStyle? parsedStyle,
    Map<ParselyType, TextStyle>? parsedStyles,
    ParselyMasks? masks,
    // ignore: deprecated_member_use
    ParselyMask? mask,
    ParselyMaskBuilder? maskBuilder,
    Set<ParselyType>? enabledEntities,
    Map<ParselyType, ValueChanged<ParselyElement>>? onTapHandlers,
    List<EntityRule> customRules = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Parsely(
            text: text,
            options: options,
            onTap: onTap,
            parsedStyle: parsedStyle,
            parsedStyles: parsedStyles,
            masks: masks,
            mask: mask,
            maskBuilder: maskBuilder,
            enabledEntities: enabledEntities,
            onTapHandlers: onTapHandlers,
            customRules: customRules,
          ),
        ),
      ),
    );
  }

  group('Parsely widget', () {
    testWidgets('renders plain / no-match', (tester) async {
      await pumpParsely(tester, text: 'hello world');
      expect(find.byType(RichText), findsOneWidget);
      expect(rebuilt(spans(tester)), 'hello world');
      // Single plain span, no recognizer.
      expect(spans(tester), hasLength(1));
      expect(spans(tester).single.recognizer, isNull);
    });

    testWidgets('renders empty', (tester) async {
      await pumpParsely(tester, text: '');
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('each entity styled with parsedStyle', (tester) async {
      const linkStyle = TextStyle(color: Colors.red);
      const emailStyle = TextStyle(color: Colors.green);
      await pumpParsely(
        tester,
        text: 'a@b.com https://x.com',
        parsedStyles: {
          ParselyType.email: emailStyle,
          ParselyType.link: linkStyle,
        },
      );
      final xs = spans(tester);
      // email, space, link (humanized display).
      expect(xs[0].style, emailStyle);
      expect(xs[2].style, linkStyle);
      expect(xs[0].recognizer, isNotNull);
      expect(xs[2].recognizer, isNotNull);
    });

    testWidgets('onTap fires correct element (tester.tap)', (tester) async {
      final tapped = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: 'a@b.com',
        parsedStyle: const TextStyle(color: Colors.blue),
        onTap: tapped.add,
      );
      await tester.tap(find.byType(RichText));
      expect(tapped, hasLength(1));
      expect(tapped.single.type, ParselyType.email);
      expect(tapped.single.parsed, 'a@b.com');
      expect(tapped.single.start, 0);
      expect(tapped.single.end, 7);
    });

    testWidgets('onTap for link carries original parsed payload',
        (tester) async {
      final tapped = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: 'https://x.com',
        onTap: tapped.add,
      );
      await tester.tap(find.byType(RichText));
      expect(tapped.single.type, ParselyType.link);
      expect(tapped.single.parsed, 'https://x.com');
      // Display is humanized, payload is original.
      expect(tapped.single.displayText, 'x.com');
    });

    testWidgets('masked display + original payload', (tester) async {
      final tapped = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: 'call +234 806 898 9116',
        onTap: tapped.add,
        masks: const ParselyMasks(exact: {'+234 806 898 9116': 'My Contact'}),
      );
      final xs = spans(tester);
      expect(xs[1].text, 'My Contact');
      // Tap the rich text (single phone span: tap center hits phone in
      // most layouts, so use a phone-only text for determinism).
      final tapped2 = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: '+234 806 898 9116',
        onTap: tapped2.add,
        masks: const ParselyMasks(exact: {'+234 806 898 9116': 'My Contact'}),
      );
      await tester.tap(find.byType(RichText));
      expect(tapped2.single.parsed, '+234 806 898 9116');
      expect(tapped2.single.displayText, 'My Contact');
      expect(tapped, isEmpty);
    });

    testWidgets('humanized display', (tester) async {
      await pumpParsely(tester, text: 'Visit https://x.com');
      final all = spans(tester).map((s) => s.text ?? '').toList();
      // Link span shows humanized `x.com`.
      expect(all, contains('x.com'));
      expect(all, isNot(contains('https://x.com')));
    });

    testWidgets('humanize false keeps display', (tester) async {
      await pumpParsely(
        tester,
        text: 'Visit https://x.com',
        options: const ParselyOptions(humanize: false),
      );
      final all = spans(tester).map((s) => s.text ?? '').toList();
      expect(all, contains('https://x.com'));
    });

    testWidgets('offset-0 regression', (tester) async {
      await pumpParsely(tester, text: '#hi there');
      // Displayed text must not duplicate the offset-0 hashtag.
      expect(rebuilt(spans(tester)), '#hi there');
      final xs = spans(tester);
      expect(xs[0].text, '#hi');
      expect(xs[0].recognizer, isNotNull);
      // Full reconstruction = original (no duplication / loss).
      expect(rebuilt(xs), '#hi there');
    });

    testWidgets('adjacent regression', (tester) async {
      await pumpParsely(tester, text: 'a@b.com #flutter');
      expect(rebuilt(spans(tester)), 'a@b.com #flutter');
      // Distinct spans: email, space, hashtag — no overlap.
      expect(spans(tester).length, 3);
    });

    testWidgets('overlap regression: email is single tap span', (tester) async {
      final tapped = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: 'user@example.com',
        onTap: tapped.add,
      );
      expect(rebuilt(spans(tester)), 'user@example.com');
      // One entity span only (not email + mention).
      final entitySpans =
          spans(tester).where((s) => s.recognizer != null).toList();
      expect(entitySpans, hasLength(1));
      expect(entitySpans.single.semanticsLabel, contains('Email'));
      await tester.tap(find.byType(RichText));
      expect(tapped.single.type, ParselyType.email);
      expect(tapped.single.parsed, 'user@example.com');
    });

    testWidgets('overlap regression: link wins over mention', (tester) async {
      await pumpParsely(tester, text: 'https://x.com/@user');
      final xs = spans(tester);
      expect(rebuilt(xs), 'x.com/@user');
      final entitySpans = xs.where((s) => s.recognizer != null).toList();
      expect(entitySpans, hasLength(1));
      expect(entitySpans.single.semanticsLabel, contains('Link'));
    });

    testWidgets('per-type styles', (tester) async {
      const red = TextStyle(color: Colors.red);
      const green = TextStyle(color: Colors.green);
      await pumpParsely(
        tester,
        text: '#flutter https://x.com',
        parsedStyles: {
          ParselyType.hashTag: red,
          ParselyType.link: green,
        },
      );
      final xs = spans(tester);
      // hashtag, space, link.
      expect(xs[0].style, red);
      expect(xs[2].style, green);
    });

    testWidgets('options toggles: parseEmail false disables email',
        (tester) async {
      await pumpParsely(
        tester,
        text: 'a@b.com',
        options: const ParselyOptions(parseEmail: false),
      );
      final xs = spans(tester);
      // No Email-labelled span (the bare-domain `b.com` may still render
      // as a link; that is engine behaviour, not an email).
      final labels = xs.map((s) => s.semanticsLabel ?? '');
      expect(labels.every((l) => !l.contains('Email')), isTrue);
      expect(rebuilt(xs), 'a@b.com');
    });

    testWidgets('options toggles: parseHashtag false gives plain text',
        (tester) async {
      await pumpParsely(
        tester,
        text: '#flutter',
        options: const ParselyOptions(parseHashtag: false),
      );
      final xs = spans(tester);
      expect(xs.where((s) => s.recognizer != null), isEmpty);
      expect(rebuilt(xs), '#flutter');
    });

    testWidgets('options toggles: enabledEntities', (tester) async {
      await pumpParsely(
        tester,
        text: 'a@b.com #flutter',
        enabledEntities: {ParselyType.email},
      );
      final xs = spans(tester);
      // Email tappable, hashtag plain (single trailing plain span).
      expect(xs[0].recognizer, isNotNull);
      expect(xs[1].recognizer, isNull);
      expect(rebuilt(xs), 'a@b.com #flutter');
    });

    testWidgets('onTapHandlers per-type', (tester) async {
      final linkTaps = <ParselyElement>[];
      final emailTaps = <ParselyElement>[];
      await pumpParsely(
        tester,
        text: 'https://x.com',
        onTapHandlers: {
          ParselyType.link: linkTaps.add,
          ParselyType.email: emailTaps.add,
        },
      );
      await tester.tap(find.byType(RichText));
      expect(linkTaps, hasLength(1));
      expect(emailTaps, isEmpty);
    });

    testWidgets('semantics labels present', (tester) async {
      await pumpParsely(
        tester,
        text: 'a@b.com #flutter',
        options: const ParselyOptions(humanize: false),
      );
      final xs = spans(tester);
      final labels =
          xs.map((s) => s.semanticsLabel).whereType<String>().toList();
      expect(labels, anyElement(contains('Email')));
      expect(labels, anyElement(contains('Hashtag')));
    });

    testWidgets('recognizer leak: dispose without error', (tester) async {
      await pumpParsely(tester, text: 'a@b.com #flutter https://x.com');
      expect(find.byType(RichText), findsOneWidget);
      // Replace with empty tree -> dispose() must not throw.
      await tester.pumpWidget(const SizedBox());
      expect(find.byType(RichText), findsNothing);
    });

    testWidgets('recognizer leak: rebuild with new text disposes old',
        (tester) async {
      await pumpParsely(tester, text: 'a@b.com');
      await pumpParsely(tester, text: '#flutter #dart');
      expect(find.byType(RichText), findsOneWidget);
      expect(rebuilt(spans(tester)), '#flutter #dart');
    });

    testWidgets('maskBuilder + legacy mask via widget', (tester) async {
      await pumpParsely(
        tester,
        text: '+234 806 898 9116',
        maskBuilder: ParselyMaskBuilders.partialLast(
            type: ParselyType.phone, keepLast: 4, char: '*'),
      );
      expect(spans(tester).single.text, '*************9116');

      // ignore: deprecated_member_use
      await pumpParsely(
        tester,
        text: 'a@b.com',
        // ignore: deprecated_member_use
        mask: ParselyMask(matches: ['a@b.com'], masks: ['hidden']),
      );
      expect(spans(tester).single.text, 'hidden');
    });
  });

  group('SelectableParsely', () {
    testWidgets('renders + tap fires', (tester) async {
      final tapped = <ParselyElement>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableParsely(
              text: 'Hi @dartlang',
              onTap: tapped.add,
            ),
          ),
        ),
      );
      expect(find.byType(SelectableParsely), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(rebuilt(selectableSpans(tester)), 'Hi dartlang');
      final xs = selectableSpans(tester);
      expect(xs.map((s) => s.semanticsLabel).whereType<String>(),
          anyElement(contains('Mention')));
      // Single-entity selectable tap.
      final tapped2 = <ParselyElement>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectableParsely(
              text: '@dartlang',
              onTap: tapped2.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SelectableText));
      expect(tapped2.single.type, ParselyType.mentionTag);
      expect(tapped2.single.parsed, '@dartlang');
    });
  });
}
