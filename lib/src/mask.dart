import "package:binkap_parsely/src/masks.dart";

/// Legacy parallel-list mask.
///
/// Deprecated: use [ParselyMasks] (map-based) or [ParselyMaskBuilder]
/// (function form) instead. See the migration guide in README §15.
///
/// ```dart
/// // Before
/// ParselyMask(matches: ['+234…'], masks: ['My Contact'])
/// // After
/// ParselyMasks(exact: {'+234…': 'My Contact'})
/// // or
/// maskBuilder: (e) => e.parsed == '+234…' ? 'My Contact' : null
/// ```
@Deprecated("Use ParselyMasks (map-based) or ParselyMaskBuilder instead")
class ParselyMask {
  /// Creates a [ParselyMask] with parallel [matches] and [masks] lists.
  ///
  /// Both lists must have equal length; see also [toMasks].
  ParselyMask({
    required this.matches,
    required this.masks,
  }) : assert(matches.length == masks.length);

  /// Values that should be masked.
  final List<String> matches;

  /// Display replacements, parallel to [matches].
  final List<String> masks;

  /// Convert to the map-based form. Throws [ArgumentError] on mismatch.
  ParselyMasks toMasks() {
    if (matches.length != masks.length) {
      throw ArgumentError("matches and masks must have equal length");
    }
    return ParselyMasks(
      exact: Map.fromEntries(List.generate(
        matches.length,
        (i) => MapEntry(matches[i], masks[i]),
      )),
    );
  }

  /// Display override for [parsed], or `null` when unmatched.
  String? resolve(String parsed) {
    final i = matches.indexOf(parsed);
    return i == -1 ? null : masks.elementAt(i);
  }
}
