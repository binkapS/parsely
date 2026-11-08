import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/option.dart';
import 'package:binkap_parsely/src/type.dart';

/// Display transforms (pure functions, no Flutter imports).
///
/// [ParselyUtil.humanize] is kept as a deprecated shim.
class ParselyHumanize {
  const ParselyHumanize._();

  static final RegExp _linkPrefix = RegExp(
    r'^(https?://)?(www\.)?',
    caseSensitive: false,
  );

  /// Strip `https://` / `www.` prefix only (anchored, no in-path stripping).
  static String stripLinkScheme(String link) {
    return link.replaceFirst(_linkPrefix, '');
  }

  /// Strip a single leading `@` from a mention.
  static String stripMentionPrefix(String mention) {
    return mention.replaceFirst(RegExp(r'^@'), '');
  }

  /// Apply enabled transforms (link scheme / mention prefix).
  static String apply(ParselyElement element, ParselyOptions options) {
    switch (element.type) {
      case ParselyType.link:
        return options.effectiveStripLinkScheme
            ? stripLinkScheme(element.parsed)
            : element.parsed;
      case ParselyType.mentionTag:
        return options.effectiveStripMentionPrefix
            ? stripMentionPrefix(element.parsed)
            : element.parsed;
      default:
        return element.parsed;
    }
  }
}
