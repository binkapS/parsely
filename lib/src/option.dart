import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/type.dart';

/// Immutable options controlling parsing and display transforms.
///
/// ```dart
/// const ParselyOptions(
///   parseEmail: true,
///   parseLink: true,
///   parsePhone: true,
///   parseHashtag: true,
///   parseMention: true,
///   stripLinkScheme: true,
///   enabledEntities: {ParselyType.link, ParselyType.email},
/// );
/// ```
class ParselyOptions {
  /// Creates [ParselyOptions] with defaults for all entity types enabled.
  ///
  /// Use [enabledEntities] or the individual `parse*` flags to restrict
  /// which entity types are recognized.
  const ParselyOptions({
    this.parseEmail = true,
    this.parseHashtag = true,
    this.parseLink = true,
    this.parsePhone = true,
    this.parseMention = true,
    this.stripLinkScheme = false,
    this.stripMentionPrefix = false,
    this.enabledEntities,
    this.validator,
  });

  /// Whether to parse email addresses.
  final bool parseEmail;

  /// Whether to parse hashtags.
  final bool parseHashtag;

  /// Whether to parse links.
  final bool parseLink;

  /// Whether to parse phone numbers.
  final bool parsePhone;

  /// Whether to parse @mentions.
  final bool parseMention;

  /// Whether to strip `https://` / `www.` from link display text.
  ///
  /// Defaults to `false`: the original link text is shown.
  final bool stripLinkScheme;

  /// Whether to strip the leading `@` from mention display text.
  ///
  /// Defaults to `false`: the original mention text is shown.
  final bool stripMentionPrefix;

  /// Canonical set override. When non-null, wins over the `parse*` bools.
  final Set<ParselyType>? enabledEntities;

  /// Optional post-match validator (e.g. to reject phone false positives).
  /// Return false to drop the candidate.
  final bool Function(ParselyElement element)? validator;

  /// Effective strip-link-scheme flag.
  bool get effectiveStripLinkScheme => stripLinkScheme;

  /// Effective strip-mention-prefix flag.
  bool get effectiveStripMentionPrefix => stripMentionPrefix;

  /// Whether [type] is enabled, considering [enabledEntities] and `parse*`.
  bool isEnabled(ParselyType type) {
    if (enabledEntities != null) return enabledEntities!.contains(type);
    return switch (type) {
      ParselyType.email => parseEmail,
      ParselyType.link => parseLink,
      ParselyType.phone => parsePhone,
      ParselyType.hashTag => parseHashtag,
      ParselyType.mentionTag => parseMention,
    };
  }

  /// Create a copy with overrides.
  ParselyOptions copyWith({
    bool? parseEmail,
    bool? parseHashtag,
    bool? parseLink,
    bool? parsePhone,
    bool? parseMention,
    bool? stripLinkScheme,
    bool? stripMentionPrefix,
    Set<ParselyType>? enabledEntities,
    bool Function(ParselyElement element)? validator,
  }) {
    return ParselyOptions(
      parseEmail: parseEmail ?? this.parseEmail,
      parseHashtag: parseHashtag ?? this.parseHashtag,
      parseLink: parseLink ?? this.parseLink,
      parsePhone: parsePhone ?? this.parsePhone,
      parseMention: parseMention ?? this.parseMention,
      stripLinkScheme: stripLinkScheme ?? this.stripLinkScheme,
      stripMentionPrefix: stripMentionPrefix ?? this.stripMentionPrefix,
      enabledEntities: enabledEntities ?? this.enabledEntities,
      validator: validator ?? this.validator,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParselyOptions &&
          parseEmail == other.parseEmail &&
          parseHashtag == other.parseHashtag &&
          parseLink == other.parseLink &&
          parsePhone == other.parsePhone &&
          parseMention == other.parseMention &&
          stripLinkScheme == other.stripLinkScheme &&
          stripMentionPrefix == other.stripMentionPrefix &&
          _setEquals(enabledEntities, other.enabledEntities) &&
          validator == other.validator;

  @override
  int get hashCode => Object.hash(
        parseEmail,
        parseHashtag,
        parseLink,
        parsePhone,
        parseMention,
        stripLinkScheme,
        stripMentionPrefix,
        enabledEntities?.hashCode,
        validator,
      );

  @override
  String toString() =>
      'ParselyOptions(parseEmail: $parseEmail, parseLink: $parseLink, '
      'parsePhone: $parsePhone, parseHashtag: $parseHashtag, '
      'parseMention: $parseMention, stripLinkScheme: $stripLinkScheme, '
      'stripMentionPrefix: $stripMentionPrefix)';
}

bool _setEquals(Set<ParselyType>? a, Set<ParselyType>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  return a.length == b.length && a.containsAll(b);
}
