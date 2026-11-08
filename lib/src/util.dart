import "package:binkap_parsely/src/element.dart";
import "package:binkap_parsely/src/humanize.dart";
import "package:binkap_parsely/src/type.dart";

/// Deprecated singleton — use [ParselyHumanize] instead.
@Deprecated("Use ParselyHumanize instead")
class ParselyUtil {
  /// Creates the internal [ParselyUtil] instance.
  ParselyUtil._();

  /// Singleton instance (deprecated, use [ParselyHumanize] instead).
  static ParselyUtil instance = ParselyUtil._();

  /// Humanizes [element] by stripping link scheme / mention prefix.
  String humanize(ParselyElement element) {
    return switch (element.type) {
      ParselyType.link => ParselyHumanize.stripLinkScheme(element.parsed),
      ParselyType.mentionTag =>
        ParselyHumanize.stripMentionPrefix(element.parsed),
      _ => element.parsed,
    };
  }
}
