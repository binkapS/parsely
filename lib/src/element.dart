import 'package:binkap_parsely/src/type.dart';

/// A single parsed entity found in source text.
///
/// [parsed] is the original source text for the entity. [displayText] is
/// what the UI shows after masking and display stripping; it never changes
/// [parsed]. [start] and [end] are 0-based code-unit offsets into the
/// original string (`start` inclusive, `end` exclusive).
class ParselyElement {
  /// Creates a [ParselyElement] of [type] from [parsed] text.
  ///
  /// [start] and [end] are optional code-unit offsets; [displayText]
  /// defaults to [parsed] when omitted.
  const ParselyElement({
    required this.type,
    required this.parsed,
    this.start = 0,
    this.end = -1,
    String? displayText,
  })  : assert(end == -1 || end >= start),
        displayText = displayText ?? parsed;

  /// The kind of entity.
  final ParselyType type;

  /// The original matched text (never mutated by masking/humanizing).
  final String parsed;

  /// 0-based start offset in the source string.
  final int start;

  /// 0-based end offset (exclusive) in the source string.
  /// When `-1`, resolves to [start] + [parsed].length.
  final int end;

  /// What should be displayed (after masking and display stripping). Defaults to [parsed].
  final String displayText;

  /// Resolved end offset.
  int get resolvedEnd => end == -1 ? start + parsed.length : end;

  /// Copy with overrides.
  ParselyElement copyWith({
    ParselyType? type,
    String? parsed,
    int? start,
    int? end,
    String? displayText,
  }) {
    final s = start ?? this.start;
    final p = parsed ?? this.parsed;
    final e = end ?? (this.end == -1 ? s + p.length : this.end);
    return ParselyElement(
      type: type ?? this.type,
      parsed: p,
      start: s,
      end: e,
      displayText: displayText ?? this.displayText,
    );
  }

  /// Launchable [Uri] for link/email/phone, or `null` for others.
  Uri? get uri {
    switch (type) {
      case ParselyType.link:
        final trimmed = parsed.trim();
        final hasScheme =
            RegExp(r"^[a-zA-Z][a-zA-Z0-9+.-]*://").hasMatch(trimmed);
        return hasScheme
            ? Uri.tryParse(trimmed)
            : Uri.tryParse('https://$trimmed');
      case ParselyType.email:
        return Uri.tryParse('mailto:$parsed');
      case ParselyType.phone:
        final tel = parsed.replaceAll(RegExp(r"[^\d+]"), '');
        return tel.isEmpty ? null : Uri.tryParse('tel:$tel');
      case ParselyType.hashTag:
      case ParselyType.mentionTag:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParselyElement &&
          type == other.type &&
          parsed == other.parsed &&
          start == other.start &&
          end == other.end &&
          displayText == other.displayText;

  @override
  int get hashCode => Object.hash(type, parsed, start, end, displayText);

  @override
  String toString() => 'ParselyElement(${type.name}, $parsed, $start-$end)';
}
