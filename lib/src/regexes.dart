import 'package:binkap_parsely/src/type.dart';

/// Pure-Dart compiled patterns for each entity type.
///
/// All patterns are `static final` so they compile once per isolate.
/// Trailing punctuation is trimmed after matching (see `EntityEngine`).
class ParselyRegexes {
  ParselyRegexes._();

  /// Priority lookup: lower wins. email (0) > link (1) > phone (2) > hashtag (3) > mention (4).
  static int priorityOf(ParselyType type) {
    return switch (type) {
      ParselyType.email => 0,
      ParselyType.link => 1,
      ParselyType.phone => 2,
      ParselyType.hashTag => 3,
      ParselyType.mentionTag => 4,
    };
  }

  /// Email: unanchored (matches embedded emails). Requires a domain with
  /// at least one dot so `a@b` does not match. Trailing punctuation is
  /// trimmed by the engine.
  static final RegExp email = RegExp(
    r"[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+",
    caseSensitive: false,
  );

  /// Link: optional scheme or `www.`, domain with TLD of 2+ letters or
  /// punycode (`xn--…`), optional port, path/query/fragment.
  static final RegExp link = RegExp(
    r"(?:https?://|www\.)?(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+(?:[a-zA-Z]{2,}|xn--[a-zA-Z0-9-]+)(?::\d{1,5})?(?:/[^\s<>()\[\]{}|\\]*)?(?:\?[^\s<>()\[\]{}|\\]*)?(?:#[^\s<>()\[\]{}|\\]*)?",
    caseSensitive: false,
  );

  /// Phone candidate: digits with spaces, dashes, parens, dots, slashes.
  static final RegExp phone = RegExp(
    r"\+?\(?\d[\d\s\-\(\)\./]{6,20}\d",
  );

  /// Phone extension suffix (e.g. ` ext. 42`, ` x123`).
  static final RegExp phoneExtension = RegExp(
    r"\s*(?:ext\.?|x)\s*\d{1,6}\s*$",
    caseSensitive: false,
  );

  /// Hashtag: `#` followed by a letter/underscore/emoji (not a digit).
  static final RegExp hashtag = RegExp(
    r"#[\p{L}\p{So}_][\p{L}\p{N}\p{So}_]*",
    unicode: true,
  );

  /// Mention: `@` followed by a letter/underscore.
  static final RegExp mention = RegExp(
    r"@[\p{L}_][\p{L}\p{N}_]*",
    unicode: true,
  );
}
