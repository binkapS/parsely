import 'package:binkap_parsely/src/type.dart';

/// A pluggable entity rule for custom entity types (e.g. order IDs, IPs).
///
/// ```dart
/// EntityRule(
///   type: ParselyType.link, // or extend ParselyType
///   regex: RegExp(r'#\d+'),
///   priority: 10,
/// )
/// ```
class EntityRule {
  /// Creates an [EntityRule] matching [regex] as [type] with [priority].
  const EntityRule({
    required this.regex,
    this.type = ParselyType.link,
    this.priority = 10,
  });

  /// Pattern to match.
  final RegExp regex;

  /// Entity type assigned to matches (used for styling/callbacks).
  final ParselyType type;

  /// Overlap priority (lower wins). Built-ins use 0–4.
  final int priority;

  @override
  String toString() => 'EntityRule($type, /$pattern/, p$priority)';

  /// The underlying regex pattern string of [regex].
  String get pattern => regex.pattern;
}
