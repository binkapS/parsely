/// The type of a parsed entity within a text.
///
/// Values are the canonical entity kinds recognized by [ParselyParser].
/// Precedence for overlapping matches is defined by [ParselyRegexes.priority]:
/// email > link > phone > hashtag > mention.
enum ParselyType {
  /// A URL or bare domain (e.g. `https://example.com`, `www.example.com`).
  link,

  /// An email address (e.g. `a@b.com`).
  email,

  /// A phone number (e.g. `+234 806 898 9116`).
  phone,

  /// A hashtag (e.g. `#flutter`).
  hashTag,

  /// An @mention (e.g. `@dartlang`).
  mentionTag,
}

/// Convenience accessors for stable display names.
extension ParselyTypeX on ParselyType {
  /// Lower-case identifier for the type (e.g. `link`).
  String get name => toString().split('.').last;
}
