import 'dart:math';

import 'package:binkap_parsely/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('benchmark', () {
    test('100KB mixed text extracts in <100ms', skip: 'benchmark', () {
      const sample =
          'Contact a@b.com or visit https://x.com/path?q=1#f or call '
          '+234 806 898 9116 or #flutter @dartlang. ';
      final big = sample * (100 * 1024 ~/ sample.length + 1);
      // Trim to ~100KB.
      final text = big.substring(0, 100 * 1024);
      final sw = Stopwatch()..start();
      final entities = ParselyParser.extract(text);
      sw.stop();
      expect(entities, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(100),
          reason: 'extract took ${sw.elapsedMilliseconds}ms');
    });
  });

  group('fuzz-ish', () {
    test('random unicode never throws + offsets hold', () {
      final rng = Random(42);
      const pool = [
        'a',
        'b',
        '@',
        '#',
        '.',
        ':',
        '/',
        ' ',
        '!',
        '9',
        'x',
        '\u{1F389}',
        'م',
        'ر',
        'ح',
        'બ',
        '中',
        '文',
        '+',
        '-',
        '(',
        ')',
      ];
      for (var iter = 0; iter < 500; iter++) {
        final len = rng.nextInt(200);
        final buf = StringBuffer();
        for (var i = 0; i < len; i++) {
          buf.write(pool[rng.nextInt(pool.length)]);
        }
        final text = buf.toString();
        final entities = ParselyParser.extract(text);
        for (final e in entities) {
          expect(e.start, greaterThanOrEqualTo(0));
          expect(e.end, greaterThanOrEqualTo(e.start));
          expect(e.end, lessThanOrEqualTo(text.length));
          expect(text.substring(e.start, e.end), e.parsed);
        }
        // replace() must not throw either.
        ParselyParser.replace(text);
      }
    });

    test('lone surrogates / empty-ish input never throws', () {
      final tricky = [
        '',
        ' ',
        '\n\n',
        '#',
        '@',
        '@#',
        'https://',
        '....',
        '\uD800', // lone high surrogate
        '\uDC00', // lone low surrogate
        '\uD800\uDC00', // valid pair
        'a\uD800b@c.com',
      ];
      for (final t in tricky) {
        expect(() => ParselyParser.extract(t), returnsNormally);
        expect(() => ParselyParser.replace(t), returnsNormally);
      }
    });
  });
}
