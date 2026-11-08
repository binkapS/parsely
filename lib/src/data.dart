import 'package:binkap_parsely/src/element.dart';

/// Internal plumbing (kept for backward compatibility).
///
/// Prefer [ParselyElement] directly; offsets live on the element itself.
class ParselyData {
  /// Creates a [ParselyData] wrapping [element] and its [match].
  ParselyData({
    required this.element,
    required this.match,
  });

  /// The parsed entity.
  final ParselyElement element;

  /// The underlying regex [Match] that produced [element].
  final Match match;
}
