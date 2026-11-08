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
    this.humanize = true,
    this.parseEmail = true,
    this.parseHashtag = true,
    this.parseLink = true,
    this.parsePhone = true,
    this.parseMention = true,
    this.stripLinkScheme,
    this.stripMentionPrefix,
    this.enabledEntities,
    this.validator,
    @Deprecated("Use parseHashtag instead") this.parseHashTag = true,
    @Deprecated("Use parseMention instead") this.parseMentionTag = true,
  }) : assert(
          parseHashtag == parseHashTag || parseHashTag == true,
          'parseHashtag / parseHashTag mismatch',
        );

  /// Legacy combined humanize flag.
  ///
  /// Maps to [stripLinkScheme] and [stripMentionPrefix] when those are not
  /// set explicitly. Kept for backward compatibility; prefer the granular
  /// flags.
  final bool humanize;

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

  /// Granular display transforms. When null, falls back to [humanize].
  final bool? stripLinkScheme;

  /// Granular display transforms. When null, falls back to [humanize].
  final bool? stripMentionPrefix;

  /// Canonical set override. When non-null, wins over the `parse*` bools.
  final Set<ParselyType>? enabledEntities;

  /// Optional post-match validator (e.g. to reject phone false positives).
  /// Return false to drop the candidate.
  final bool Function(ParselyElement element)? validator;

  /// Deprecated: use [parseHashtag].
  final bool parseHashTag;

  /// Deprecated: use [parseMention].
  final bool parseMentionTag;

  /// Effective strip-link-scheme flag.
  bool get effectiveStripLinkScheme => stripLinkScheme ?? humanize;

  /// Effective strip-mention-prefix flag.
  bool get effectiveStripMentionPrefix => stripMentionPrefix ?? humanize;

  /// Whether [type] is enabled, considering [enabledEntities] and `parse*`.
  bool isEnabled(ParselyType type) {
    if (enabledEntities != null) return enabledEntities!.contains(type);
    return switch (type) {
      ParselyType.email => parseEmail,
      ParselyType.link => parseLink,
      ParselyType.phone => parsePhone,
      ParselyType.hashTag => parseHashtag && parseHashTag,
      ParselyType.mentionTag => parseMention && parseMentionTag,
    };
  }

  /// Create a copy with overrides.
  ParselyOptions copyWith({
    bool? humanize,
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
      humanize: humanize ?? this.humanize,
      parseEmail: parseEmail ?? this.parseEmail,
      parseHashtag: parseHashtag ?? this.parseHashtag,
      parseLink: parseLink ?? this.parseLink,
      parsePhone: parsePhone ?? this.parsePhone,
      parseMention: parseMention ?? this.parseMention,
      stripLinkScheme: stripLinkScheme ?? this.stripLinkScheme,
      stripMentionPrefix: stripMentionPrefix ?? this.stripMentionPrefix,
      enabledEntities: enabledEntities ?? this.enabledEntities,
      validator: validator ?? this.validator,
      // ignore: deprecated_member_use_from_same_package
      parseHashTag: parseHashTag,
      // ignore: deprecated_member_use_from_same_package
      parseMentionTag: parseMentionTag,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParselyOptions &&
          humanize == other.humanize &&
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
        humanize,
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
      'parseMention: $parseMention, humanize: $humanize)';
}

bool _setEquals(Set<ParselyType>? a, Set<ParselyType>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  return a.length == b.length && a.containsAll(b);
}
