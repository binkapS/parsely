import 'package:binkap_parsely/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers --------------------------------------------------------

  List<ParselyElement> ofType(String text, ParselyType type,
      {ParselyOptions? options}) {
    return ParselyParser.extract(text,
            options: options ?? const ParselyOptions())
        .where((e) => e.type == type)
        .toList();
  }

  List<String> parsedOf(String text, ParselyType type,
      {ParselyOptions? options}) {
    return ofType(text, type, options: options).map((e) => e.parsed).toList();
  }

  List<ParselyElement> emailOnly(String text) => ParselyParser.extract(text,
      options: const ParselyOptions(enabledEntities: {ParselyType.email}));

  List<ParselyElement> linkOnly(String text) => ParselyParser.extract(text,
      options: const ParselyOptions(enabledEntities: {ParselyType.link}));

  void expectOffsets(String text, List<ParselyElement> entities) {
    for (final e in entities) {
      expect(e.start, greaterThanOrEqualTo(0),
          reason: 'start >= 0 for $e in "$text"');
      expect(e.end, greaterThanOrEqualTo(e.start),
          reason: 'end >= start for $e in "$text"');
      expect(e.end, lessThanOrEqualTo(text.length),
          reason: 'end within text for $e in "$text"');
      // parsed is the exact source slice.
      expect(text.substring(e.start, e.end), e.parsed,
          reason: 'substring(start,end) == parsed for $e in "$text"');
    }
    // Non-overlapping, sorted by start.
    for (var i = 1; i < entities.length; i++) {
      expect(entities[i].start, greaterThanOrEqualTo(entities[i - 1].end),
          reason:
              'non-overlapping for "$text": ${entities[i - 1]} then ${entities[i]}');
    }
  }

  // EMAIL ----------------------------------------------------------

  group('Email', () {
    // input -> expected email parsed values (with default options).
    const table = <String, List<String>>{
      'a@b.co': ['a@b.co'],
      'first.last+tag@sub.domain.example': [
        'first.last+tag@sub.domain.example'
      ],
      'A@B.COM': ['A@B.COM'],
      'Contact me at a@b.com please': ['a@b.com'],
      'Contact a@b.com.': ['a@b.com'],
      'Mail a@b.com, thanks': ['a@b.com'],
      'Mail a@b.com; thanks': ['a@b.com'],
      'Mail a@b.com: thanks': ['a@b.com'],
      'Mail a@b.com! thanks': ['a@b.com'],
      'Mail a@b.com? thanks': ['a@b.com'],
      '(see a@b.com)': ['a@b.com'],
    };

    table.forEach((input, expected) {
      test('email matches "$input"', () {
        final found = parsedOf(input, ParselyType.email);
        expect(found, expected);
        expectOffsets(input, ofType(input, ParselyType.email));
      });
    });

    // Invalid candidates: no *email* entity. `a b@c.com` is special: the
    // whole candidate is invalid, but the embedded `b@c.com` after the
    // space is a legitimate standalone email and is extracted.
    test('email invalid: a@', () {
      expect(parsedOf('a@', ParselyType.email), isEmpty);
      expect(emailOnly('a@'), isEmpty);
    });

    test('email invalid: @b.com (no email)', () {
      expect(parsedOf('@b.com', ParselyType.email), isEmpty);
      expect(emailOnly('@b.com'), isEmpty);
    });

    test('email invalid: a@@b.com (no email)', () {
      expect(parsedOf('a@@b.com', ParselyType.email), isEmpty);
      expect(emailOnly('a@@b.com'), isEmpty);
    });

    test('email invalid: a b@c.com is not a single email', () {
      final found = ofType('a b@c.com', ParselyType.email);
      // No single entity may span the space.
      expect(found.every((e) => !e.parsed.contains(' ')), isTrue);
      expect(found.map((e) => e.parsed), isNot(contains('a b@c.com')));
      // The embedded `b@c.com` after the boundary is valid standalone.
      expect(found.map((e) => e.parsed), ['b@c.com']);
      expectOffsets('a b@c.com', found);
    });

    test('email invalid: a@b..com', () {
      expect(parsedOf('a@b..com', ParselyType.email), isEmpty);
      expect(emailOnly('a@b..com'), isEmpty);
    });
  });

  // LINK -----------------------------------------------------------

  group('Link', () {
    const mustMatch = <String, String>{
      'https://example.com': 'https://example.com',
      'http://example.com': 'http://example.com',
      'www.example.com/path?q=1#f': 'www.example.com/path?q=1#f',
      'example.technology': 'example.technology',
      'xn--nxasmq6b.example': 'xn--nxasmq6b.example',
      'example.com:8080/': 'example.com:8080/',
      'Visit https://x.com.': 'https://x.com',
      'Go to www.example.com.': 'www.example.com',
      '(see https://x.com/path)': 'https://x.com/path',
    };

    mustMatch.forEach((input, expected) {
      test('link matches "$input"', () {
        final found = parsedOf(input, ParselyType.link);
        expect(found, contains(expected));
        expectOffsets(input, ofType(input, ParselyType.link));
      });
    });

    test('link must NOT match example.c (1-char TLD)', () {
      expect(parsedOf('example.c', ParselyType.link), isEmpty);
      expect(linkOnly('example.c'), isEmpty);
    });

    test('link must NOT match http:// alone', () {
      expect(parsedOf('http://', ParselyType.link), isEmpty);
      expect(linkOnly('http://'), isEmpty);
    });

    test('link must NOT match www. alone', () {
      expect(parsedOf('www.', ParselyType.link), isEmpty);
      expect(linkOnly('www.'), isEmpty);
    });

    test('link: foo@bar.com is an email, not a bare link (email wins)', () {
      final all = ParselyParser.extract('foo@bar.com');
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.email);
      expect(all.single.parsed, 'foo@bar.com');
      expectOffsets('foo@bar.com', all);
    });

    test('link: https://x.com/@user single link wins', () {
      final all = ParselyParser.extract('https://x.com/@user');
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.link);
      expect(all.single.parsed, 'https://x.com/@user');
      expectOffsets('https://x.com/@user', all);
    });
  });

  // PHONE ----------------------------------------------------------

  group('Phone', () {
    const mustMatch = <String, String>{
      '+234 806 898 9116': '+234 806 898 9116',
      '(0803) 123-4567': '(0803) 123-4567',
      '0803/1234567': '0803/1234567',
    };

    mustMatch.forEach((input, expected) {
      test('phone matches "$input"', () {
        final found = parsedOf(input, ParselyType.phone);
        expect(found, contains(expected));
        expectOffsets(input, ofType(input, ParselyType.phone));
      });
    });

    test('phone must NOT match too-short 123456', () {
      expect(parsedOf('123456', ParselyType.phone), isEmpty);
    });

    test('phone must NOT match date 2024-01-15', () {
      expect(parsedOf('2024-01-15', ParselyType.phone), isEmpty);
    });

    test('phone must NOT match card-like long digit run', () {
      expect(parsedOf('1234 5678 9012 3456', ParselyType.phone), isEmpty);
    });
  });

  // HASHTAG / MENTION ----------------------------------------------

  group('Hashtag', () {
    const mustMatch = <String, String>{
      '#flutter': '#flutter',
      '#🎉': '#🎉',
      '#مرحبا': '#مرحبا',
      '#_private': '#_private',
    };

    mustMatch.forEach((input, expected) {
      test('hashtag matches "$input"', () {
        expect(parsedOf(input, ParselyType.hashTag), contains(expected));
        expectOffsets(input, ofType(input, ParselyType.hashTag));
      });
    });

    test('hashtag #123 NOT', () {
      expect(parsedOf('#123', ParselyType.hashTag), isEmpty);
    });

    test('hashtag #1 NOT', () {
      expect(parsedOf('#1', ParselyType.hashTag), isEmpty);
    });

    test('hashtag a#b NOT (no preceding boundary)', () {
      expect(parsedOf('a#b', ParselyType.hashTag), isEmpty);
    });

    test('hashtag # alone NOT', () {
      expect(parsedOf('#', ParselyType.hashTag), isEmpty);
    });
  });

  group('Mention', () {
    const mustMatch = <String, String>{
      '@dartlang': '@dartlang',
      '@binkap': '@binkap',
    };

    mustMatch.forEach((input, expected) {
      test('mention matches "$input"', () {
        expect(parsedOf(input, ParselyType.mentionTag), contains(expected));
        expectOffsets(input, ofType(input, ParselyType.mentionTag));
      });
    });

    test('mention @123 NOT', () {
      expect(parsedOf('@123', ParselyType.mentionTag), isEmpty);
    });

    test('mention email-tail NOT (user@example.com)', () {
      expect(parsedOf('user@example.com', ParselyType.mentionTag), isEmpty);
      final all = ParselyParser.extract('user@example.com');
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.email);
    });

    test('mention @@user NOT', () {
      expect(parsedOf('@@user', ParselyType.mentionTag), isEmpty);
    });
  });

  // OVERLAP / PRIORITY ---------------------------------------------

  group('Overlap / priority', () {
    test('user@example.com single email', () {
      final all = ParselyParser.extract('user@example.com');
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.email);
      expect(all.single.parsed, 'user@example.com');
      expectOffsets('user@example.com', all);
    });

    test('https://x.com/@user single link', () {
      final all = ParselyParser.extract('https://x.com/@user');
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.link);
      expect(all.single.parsed, 'https://x.com/@user');
      expectOffsets('https://x.com/@user', all);
    });

    test('adjacent entities', () {
      const text = 'a@b.com #flutter';
      final all = ParselyParser.extract(text);
      expect(all, hasLength(2));
      expect(all[0].type, ParselyType.email);
      expect(all[1].type, ParselyType.hashTag);
      expectOffsets(text, all);
    });

    test('all entities together, sorted + non-overlapping', () {
      const text = '#flutter @dartlang https://x.com a@b.com +234 806 898 9116';
      final all = ParselyParser.extract(text);
      expect(all.length, 5);
      expect(all.map((e) => e.type), [
        ParselyType.hashTag,
        ParselyType.mentionTag,
        ParselyType.link,
        ParselyType.email,
        ParselyType.phone,
      ]);
      expectOffsets(text, all);
    });

    test('entity at 0', () {
      final all = ParselyParser.extract('#flutter there');
      expect(all, hasLength(1));
      expect(all.single.start, 0);
      expect(all.single.parsed, '#flutter');
      expectOffsets('#flutter there', all);
    });

    test('entity at end', () {
      const text = 'hello #flutter';
      final all = ParselyParser.extract(text);
      expect(all, hasLength(1));
      expect(all.single.end, text.length);
      expectOffsets(text, all);
    });

    test('empty input', () {
      expect(ParselyParser.extract(''), isEmpty);
    });

    test('no-match input', () {
      expect(ParselyParser.extract('hello world'), isEmpty);
    });

    test('matches-only input', () {
      final all = ParselyParser.extract('a@b.com');
      expect(all, hasLength(1));
      expect(all.single.start, 0);
      expect(all.single.end, 'a@b.com'.length);
    });

    test('regression offset-0', () {
      // No duplication / loss at offset 0. The span builder must not
      // re-emit the entity as plain text.
      const text = '#hi there';
      final all = ParselyParser.extract(text);
      expect(all, hasLength(1));
      expect(all.single.start, 0);
      // Reconstruction with display text must equal original with entity
      // substituted (no duplication of the entity at the front).
      final replaced = ParselyParser.replace(text);
      expect(replaced, isNot(contains('#hi#hi')));
      expectOffsets(text, all);
    });

    test('regression overlap email mention', () {
      const text = 'user@example.com';
      final all = ParselyParser.extract(text);
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.email);
      expect(all.where((e) => e.type == ParselyType.mentionTag), isEmpty);
      expectOffsets(text, all);
    });
  });

  // HUMANIZE / MASK -------------------------------------------------

  group('Humanize / mask', () {
    test('ParselyHumanize.stripLinkScheme https://x.com -> x.com', () {
      expect(ParselyHumanize.stripLinkScheme('https://x.com'), 'x.com');
    });

    test('ParselyHumanize.stripLinkScheme keeps path www', () {
      // Anchored prefix strip only: in-path `www.` survives.
      expect(ParselyHumanize.stripLinkScheme('https://x.com/www.page'),
          'x.com/www.page');
    });

    test('ParselyHumanize.stripMentionPrefix', () {
      expect(ParselyHumanize.stripMentionPrefix('@user'), 'user');
    });

    test('humanize true strips scheme by default', () {
      final all = ParselyParser.extract('Visit https://x.com');
      expect(all.single.parsed, 'https://x.com');
      expect(all.single.displayText, 'x.com');
      expectOffsets('Visit https://x.com', all);
    });

    test('humanize false keeps scheme', () {
      final all = ParselyParser.extract('Visit https://x.com',
          options: const ParselyOptions(humanize: false));
      expect(all.single.displayText, 'https://x.com');
    });

    test('@ stripping when humanize true', () {
      final all = ParselyParser.extract('Hi @user');
      expect(all.single.type, ParselyType.mentionTag);
      expect(all.single.parsed, '@user');
      expect(all.single.displayText, 'user');
    });

    test('ParselyHumanize.apply respects options', () {
      const e = ParselyElement(type: ParselyType.link, parsed: 'https://x.com');
      expect(ParselyHumanize.apply(e, const ParselyOptions(humanize: false)),
          'https://x.com');
      expect(ParselyHumanize.apply(e, const ParselyOptions()), 'x.com');
      const m = ParselyElement(type: ParselyType.mentionTag, parsed: '@hi');
      expect(ParselyHumanize.apply(m, const ParselyOptions()), 'hi');
      expect(
          ParselyHumanize.apply(
              m, const ParselyOptions(stripMentionPrefix: false)),
          '@hi');
    });

    test('stripLinkScheme / stripMentionPrefix granular flags', () {
      final all = ParselyParser.extract('Hi @user https://x.com',
          options: const ParselyOptions(
              stripLinkScheme: false, stripMentionPrefix: false));
      expect(all[0].displayText, '@user');
      expect(all[1].displayText, 'https://x.com');
    });

    test('ParselyMasks exact', () {
      final all = ParselyParser.extract('call +234 806 898 9116',
          masks:
              const ParselyMasks(exact: {'+234 806 898 9116': 'My Contact'}));
      expect(all.single.parsed, '+234 806 898 9116');
      expect(all.single.displayText, 'My Contact');
    });

    test('ParselyMasks patterns', () {
      final all = ParselyParser.extract('a@b.com hello',
          masks: ParselyMasks(patterns: [(RegExp(r'.*@.*'), 'MASKED')]));
      expect(all.single.displayText, 'MASKED');
    });

    test('ParselyMasks maskAll by type', () {
      final all = ParselyParser.extract('a@b.com hello',
          masks: const ParselyMasks(maskAll: {ParselyType.email}));
      expect(all.single.displayText,
          ParselyMasks.defaultMaskFor(ParselyType.email));
    });

    test('maskBuilder wins (highest precedence)', () {
      final all = ParselyParser.extract('call +234 806 898 9116',
          masks: const ParselyMasks(exact: {'+234 806 898 9116': 'Exact'}),
          maskBuilder: (e) => 'Built');
      expect(all.single.displayText, 'Built');
    });

    test('partialLast maskBuilder', () {
      final builder = ParselyMaskBuilders.partialLast(
          type: ParselyType.phone, keepLast: 4, char: '*');
      final all =
          ParselyParser.extract('call +234 806 898 9116', maskBuilder: builder);
      const p = '+234 806 898 9116';
      expect(all.single.displayText,
          '*' * (p.length - 4) + p.substring(p.length - 4));
      expect(all.single.parsed, p);
    });

    test('partialLast respects type filter', () {
      final builder = ParselyMaskBuilders.partialLast(
          type: ParselyType.phone, keepLast: 4, char: '*');
      const phone = ParselyElement(type: ParselyType.phone, parsed: '12345678');
      expect(builder(phone), '****5678');
      const email = ParselyElement(type: ParselyType.email, parsed: 'a@b.com');
      expect(builder(email), isNull);
    });

    test('legacy ParselyMask', () {
      // ignore: deprecated_member_use_from_same_package
      final all = ParselyParser.extract('a@b.com hello',
          // ignore: deprecated_member_use_from_same_package
          mask: ParselyMask(matches: ['a@b.com'], masks: ['hidden']));
      expect(all.single.displayText, 'hidden');
      expect(all.single.parsed, 'a@b.com');
    });

    test('mask wins over humanize', () {
      // displayText is derived after mask > humanize: a masked link must
      // show the mask, not the humanized form.
      final all = ParselyParser.extract('Visit https://x.com',
          masks: const ParselyMasks(exact: {'https://x.com': 'Hidden link'}));
      expect(all.single.displayText, 'Hidden link');
    });

    test('no-mask fallback is humanized/parsed display', () {
      final all = ParselyParser.extract('a@b.com hello #flutter',
          // No masks at all.
          options: const ParselyOptions(humanize: false));
      expect(all[0].displayText, all[0].parsed);
      expect(all[1].displayText, all[1].parsed);
    });

    test('ParselyMask legacy resolve + toMasks + mismatch', () {
      // ignore: deprecated_member_use_from_same_package
      final legacy =
          // ignore: deprecated_member_use_from_same_package
          ParselyMask(matches: ['a', 'b'], masks: ['A', 'B']);
      expect(legacy.resolve('a'), 'A');
      expect(legacy.resolve('nope'), isNull);
      expect(legacy.toMasks().exact, {'a': 'A', 'b': 'B'});
      // Mismatched parallel lists fail loudly (assert in debug,
      // ArgumentError from toMasks() on release paths).
      expect(
        () => // ignore: deprecated_member_use_from_same_package
            ParselyMask(matches: ['a'], masks: ['A', 'B']).toMasks(),
        throwsA(anyOf(isA<ArgumentError>(), isA<AssertionError>())),
      );
    });
  });

  // OPTIONS / API ---------------------------------------------------

  group('Options toggles', () {
    const mixed = 'a@b.com #flutter https://x.com @hi +234 806 898 9116';

    test('no toggles on -> no entities', () {
      final all = ParselyParser.extract(mixed,
          options: const ParselyOptions(
            parseEmail: false,
            parseLink: false,
            parsePhone: false,
            parseHashtag: false,
            parseMention: false,
          ));
      expect(all, isEmpty);
    });

    test('each parse* toggle individually', () {
      expect(
          ofType(mixed, ParselyType.email,
              options: const ParselyOptions(parseEmail: false)),
          isEmpty);
      expect(
          ofType(mixed, ParselyType.link,
              options: const ParselyOptions(parseLink: false)),
          isEmpty);
      expect(
          ofType(mixed, ParselyType.phone,
              options: const ParselyOptions(parsePhone: false)),
          isEmpty);
      expect(
          ofType(mixed, ParselyType.hashTag,
              options: const ParselyOptions(parseHashtag: false)),
          isEmpty);
      expect(
          ofType(mixed, ParselyType.mentionTag,
              options: const ParselyOptions(parseMention: false)),
          isEmpty);
    });

    test('enabledEntities set wins', () {
      final all = ParselyParser.extract(mixed,
          options: const ParselyOptions(enabledEntities: {ParselyType.email}));
      expect(all, hasLength(1));
      expect(all.single.type, ParselyType.email);
    });

    test('validator hook drops candidates', () {
      final all = ParselyParser.extract('+234 806 898 9116',
          options:
              ParselyOptions(validator: (e) => e.type != ParselyType.phone));
      expect(all, isEmpty);
    });

    test('isEnabled / effective flags', () {
      const o = ParselyOptions(
          enabledEntities: {ParselyType.link, ParselyType.email});
      expect(o.isEnabled(ParselyType.link), isTrue);
      expect(o.isEnabled(ParselyType.phone), isFalse);
      expect(const ParselyOptions().effectiveStripLinkScheme, isTrue);
      expect(
          const ParselyOptions(humanize: false, stripLinkScheme: true)
              .effectiveStripLinkScheme,
          isTrue);
    });
  });

  group('Custom rules', () {
    test('EntityRule extracts custom entity', () {
      final all = ParselyParser.extract('Order #12345 here', customRules: [
        EntityRule(regex: RegExp(r'#\d+'), type: ParselyType.link, priority: 10)
      ]);
      expect(all, hasLength(1));
      expect(all.single.parsed, '#12345');
      expectOffsets('Order #12345 here', all);
    });
  });

  group('Headless API', () {
    test('replace() substitutes display text', () {
      expect(ParselyParser.replace('Mail a@b.com!'), 'Mail a@b.com!');
      // Humanized link display via replace.
      expect(ParselyParser.replace('Visit https://x.com'), 'Visit x.com');
      // Mask via replace.
      expect(
          ParselyParser.replace('call +234 806 898 9116',
              masks: const ParselyMasks(
                  exact: {'+234 806 898 9116': 'My Contact'})),
          'call My Contact');
      // No entities: identity.
      expect(ParselyParser.replace('hello world'), 'hello world');
    });

    test('replace() preserves surrounding text + trailing punctuation', () {
      expect(ParselyParser.replace('Visit https://x.com.'), 'Visit x.com.');
    });

    test('contains()', () {
      expect(
          ParselyParser.contains('Mail a@b.com!', ParselyType.email), isTrue);
      expect(
          ParselyParser.contains('Mail a@b.com!', ParselyType.link), isFalse);
      expect(ParselyParser.contains('hello', ParselyType.hashTag), isFalse);
    });

    test('firstOfType()', () {
      final e =
          ParselyParser.firstOfType('Mail a@b.com! #hi', ParselyType.email);
      expect(e, isNotNull);
      expect(e!.parsed, 'a@b.com');
      expect(ParselyParser.firstOfType('hello', ParselyType.email), isNull);
      // First, not second.
      final first =
          ParselyParser.firstOfType('a@b.com then c@d.com', ParselyType.email);
      expect(first!.parsed, 'a@b.com');
    });

    test('engine is pure / idempotent across calls', () {
      final a = ParselyParser.extract('a@b.com');
      final b = ParselyParser.extract('a@b.com');
      expect(a, b);
    });
  });

  group('ParselyElement model', () {
    test('equality + hashCode', () {
      const a = ParselyElement(
          type: ParselyType.email, parsed: 'a@b.com', start: 0, end: 7);
      const b = ParselyElement(
          type: ParselyType.email, parsed: 'a@b.com', start: 0, end: 7);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      const c = ParselyElement(
          type: ParselyType.link, parsed: 'a@b.com', start: 0, end: 7);
      expect(a, isNot(c));
      const d = ParselyElement(
          type: ParselyType.email,
          parsed: 'a@b.com',
          start: 0,
          end: 7,
          displayText: 'x');
      expect(a, isNot(d));
    });

    test('copyWith', () {
      const a = ParselyElement(
          type: ParselyType.email, parsed: 'a@b.com', start: 0, end: 7);
      final b = a.copyWith(displayText: 'x');
      expect(b.displayText, 'x');
      expect(b.parsed, 'a@b.com');
      expect(b.type, ParselyType.email);
      expect(b.start, 0);
      expect(b.end, 7);
      expect(a.copyWith(), a);
    });

    test('uri', () {
      expect(
          const ParselyElement(type: ParselyType.email, parsed: 'a@b.com').uri,
          Uri.parse('mailto:a@b.com'));
      expect(const ParselyElement(type: ParselyType.link, parsed: 'x.com').uri,
          Uri.parse('https://x.com'));
      expect(
          const ParselyElement(type: ParselyType.link, parsed: 'https://x.com')
              .uri,
          Uri.parse('https://x.com'));
      expect(
          const ParselyElement(
                  type: ParselyType.phone, parsed: '+234 806 898 9116')
              .uri,
          Uri.parse('tel:+2348068989116'));
      expect(const ParselyElement(type: ParselyType.hashTag, parsed: '#hi').uri,
          isNull);
      expect(
          const ParselyElement(type: ParselyType.mentionTag, parsed: '@hi').uri,
          isNull);
    });

    test('toString', () {
      const a = ParselyElement(
          type: ParselyType.email, parsed: 'a@b.com', start: 0, end: 7);
      expect(a.toString(), contains('email'));
      expect(a.toString(), contains('a@b.com'));
    });

    test('resolvedEnd when end == -1', () {
      expect(
          const ParselyElement(
                  type: ParselyType.email, parsed: 'a@b.com', start: 5)
              .resolvedEnd,
          12);
    });
  });

  group('ParselyOptions model', () {
    test('equality + hashCode', () {
      expect(const ParselyOptions(), const ParselyOptions());
      expect(const ParselyOptions().hashCode, const ParselyOptions().hashCode);
      expect(const ParselyOptions(),
          isNot(const ParselyOptions(parseEmail: false)));
      expect(const ParselyOptions(enabledEntities: {ParselyType.email}),
          const ParselyOptions(enabledEntities: {ParselyType.email}));
    });

    test('copyWith', () {
      const a = ParselyOptions();
      final b = a.copyWith(parseEmail: false);
      expect(b.parseEmail, isFalse);
      expect(b.parseLink, isTrue);
      expect(a.copyWith(), a);
    });

    test('toString', () {
      expect(const ParselyOptions().toString(), contains('ParselyOptions'));
    });
  });

  group('Misc core', () {
    test('ParselyRegexes.priorityOf ordering', () {
      expect(ParselyRegexes.priorityOf(ParselyType.email),
          lessThan(ParselyRegexes.priorityOf(ParselyType.link)));
      expect(ParselyRegexes.priorityOf(ParselyType.link),
          lessThan(ParselyRegexes.priorityOf(ParselyType.phone)));
      expect(ParselyRegexes.priorityOf(ParselyType.phone),
          lessThan(ParselyRegexes.priorityOf(ParselyType.hashTag)));
      expect(ParselyRegexes.priorityOf(ParselyType.hashTag),
          lessThan(ParselyRegexes.priorityOf(ParselyType.mentionTag)));
    });

    test('ParselyTypeX.name', () {
      expect(ParselyType.link.name, 'link');
      expect(ParselyType.email.name, 'email');
    });

    test('ParselyLaunch helpers', () {
      const e = ParselyElement(type: ParselyType.email, parsed: 'a@b.com');
      expect(ParselyLaunch.uriFor(e), e.uri);
      expect(ParselyLaunch.schemeFor(e), 'mailto');
      expect(ParselyLaunch.labelFor(e), 'a@b.com');
    });

    test('ParselyMasks resolve / masksType', () {
      const masks = ParselyMasks(exact: {'a@b.com': 'x'});
      const e = ParselyElement(type: ParselyType.email, parsed: 'a@b.com');
      expect(masks.resolve(e), 'x');
      expect(masks.masksType(ParselyType.email), isFalse);
      expect(
          const ParselyMasks(maskAll: {ParselyType.email})
              .masksType(ParselyType.email),
          isTrue);
    });

    test('ParselyMaskBuilders.fixed', () {
      final b = ParselyMaskBuilders.fixed('HIDDEN', type: ParselyType.phone);
      expect(b(const ParselyElement(type: ParselyType.phone, parsed: '1')),
          'HIDDEN');
      expect(b(const ParselyElement(type: ParselyType.email, parsed: 'a')),
          isNull);
    });

    test('legacy ParselyUtil.humanize', () {
      // ignore: deprecated_member_use_from_same_package
      final u = ParselyUtil.instance;
      // ignore: deprecated_member_use_from_same_package
      expect(
          u.humanize(const ParselyElement(
              type: ParselyType.link, parsed: 'https://x.com')),
          'x.com');
      // ignore: deprecated_member_use_from_same_package
      expect(
          u.humanize(const ParselyElement(
              type: ParselyType.mentionTag, parsed: '@bob')),
          'bob');
    });
  });
}
