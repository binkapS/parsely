import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/type.dart';

/// Function form of masking: return a display override or `null` for no mask.
///
/// This is the most flexible masking API (zero config):
/// ```dart
/// Parsely(
///   maskBuilder: (e) => e.type == ParselyType.phone
///       ? '•' * 6 + e.parsed.suffix(4)
///       : null,
/// )
/// ```
typedef ParselyMaskBuilder = String? Function(ParselyElement element);

/// Map-based masking configuration.
///
/// Precedence when resolving a mask: [ParselyMaskBuilder] (if provided)
/// → [fromBuilder] → exact → patterns → [maskAll] → stripped display.
class ParselyMasks {
  /// Creates a [ParselyMasks] config from [exact], [patterns] and [maskAll].
  const ParselyMasks({
    this.exact = const {},
    this.patterns = const [],
    this.maskAll = const {},
  });

  /// Exact decoded value → display replacement.
  final Map<String, String> exact;

  /// Pattern → replacement pairs. The [Pattern] may be a [RegExp].
  /// The first matching entry wins.
  final List<(Pattern, String)> patterns;

  /// Mask every entity of these types.
  ///
  /// [maskAll] stores type → display text. When empty the default for a
  /// masked type is `'•' * 4` for phones and the empty string otherwise?
  /// Instead, use [ParselyMasks.forType] or [ParselyMasks.partial].
  ///
  /// When [maskAll] is empty this set does nothing. Use
  /// [ParselyMasks.partial] for the common “keep last N” UX.
  final Set<ParselyType> maskAll;

  /// Returns the display override for [element], or `null` for no mask.
  String? resolve(ParselyElement element) {
    final e = exact[element.parsed];
    if (e != null) return e;
    for (final (pattern, replacement) in patterns) {
      if (pattern.allMatches(element.parsed).isNotEmpty) return replacement;
    }
    return null;
  }

  /// Whether [element] should be masked by type.
  bool masksType(ParselyType type) => maskAll.contains(type);

  /// Default display for a [maskAll] type: `•` repeated 4 times.
  static String defaultMaskFor(ParselyType type) => '•' * 4;
}

/// Builder helpers for common masks.
class ParselyMaskBuilders {
  const ParselyMaskBuilders._();

  /// Keep-last-N partial mask for a specific type (or all types).
  static ParselyMaskBuilder partialLast({
    ParselyType? type,
    int keepLast = 4,
    String char = '•',
  }) {
    return (element) {
      if (type != null && element.type != type) return null;
      final parsed = element.parsed;
      if (parsed.length <= keepLast) return parsed;
      return char * (parsed.length - keepLast) +
          parsed.substring(parsed.length - keepLast);
    };
  }

  /// Fixed placeholder for a type.
  static ParselyMaskBuilder fixed(String mask, {ParselyType? type}) {
    return (element) => (type == null || element.type == type) ? mask : null;
  }
}
