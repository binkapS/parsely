import "package:binkap_parsely/src/element.dart";
import "package:binkap_parsely/src/humanize.dart";
import "package:binkap_parsely/src/mask.dart";
import "package:binkap_parsely/src/masks.dart";
import "package:binkap_parsely/src/option.dart";
import "package:binkap_parsely/src/regexes.dart";
import "package:binkap_parsely/src/rule.dart";
import "package:binkap_parsely/src/type.dart";

/// Raw match before overlap resolution.
class _RawMatch {
  _RawMatch({
    required this.type,
    required this.parsed,
    required this.start,
    required this.end,
    required this.priority,
  });
  final ParselyType type;
  final String parsed;
  final int start;
  final int end;
  final int priority;
}

/// Pure-Dart entity engine (no Flutter imports).
///
/// Guarantees non-overlapping, in-order spans with deterministic priority
/// `email > link > phone > hashtag > mention > custom`.
class EntityEngine {
  const EntityEngine._();

  static final RegExp _datePattern = RegExp(r"\d{4}[-\/]\d{2}[-\/]\d{2}");
  static final RegExp _emailLocalChars =
      RegExp(r"[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]");
  static final RegExp _boundaryPrev = RegExp(r'''[\s\(\["']''');

  /// Extract entities from [text].
  static List<ParselyElement> extract(
    String text, {
    ParselyOptions options = const ParselyOptions(),
    ParselyMasks? masks,
    // ignore: deprecated_member_use_from_same_package
    ParselyMask? mask,
    ParselyMaskBuilder? maskBuilder,
    List<EntityRule> customRules = const [],
  }) {
    if (text.isEmpty) return const [];

    final raw = <_RawMatch>[];

    void collect(RegExp regex, ParselyType type, int priority) {
      for (final m in regex.allMatches(text)) {
        final start = m.start;
        var end = m.end;
        var parsed = m.group(0)!;
        if (type == ParselyType.link || type == ParselyType.email) {
          final trimmed = _trimTrailingPunctuation(parsed);
          parsed = trimmed;
          end = start + parsed.length;
        } else {
          end = start + parsed.length;
        }
        if (parsed.isEmpty) continue;
        if (!_validate(type, parsed, text, start, end)) continue;
        raw.add(_RawMatch(
            type: type,
            parsed: parsed,
            start: start,
            end: end,
            priority: priority));
      }
    }

    if (options.isEnabled(ParselyType.email)) {
      collect(ParselyRegexes.email, ParselyType.email, 0);
    }
    if (options.isEnabled(ParselyType.link)) {
      collect(ParselyRegexes.link, ParselyType.link, 1);
    }
    if (options.isEnabled(ParselyType.phone)) {
      collect(ParselyRegexes.phone, ParselyType.phone, 2);
    }
    if (options.isEnabled(ParselyType.hashTag)) {
      collect(ParselyRegexes.hashtag, ParselyType.hashTag, 3);
    }
    if (options.isEnabled(ParselyType.mentionTag)) {
      collect(ParselyRegexes.mention, ParselyType.mentionTag, 4);
    }

    for (final rule in customRules) {
      for (final m in rule.regex.allMatches(text)) {
        final parsed = m.group(0)!;
        if (parsed.isEmpty) continue;
        raw.add(_RawMatch(
          type: rule.type,
          parsed: parsed,
          start: m.start,
          end: m.start + parsed.length,
          priority: rule.priority,
        ));
      }
    }

    if (raw.isEmpty) return const [];

    raw.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      final byLen = b.parsed.length.compareTo(a.parsed.length);
      if (byLen != 0) return byLen;
      return a.priority.compareTo(b.priority);
    });

    final accepted = <_RawMatch>[];
    var lastEnd = -1;
    for (final r in raw) {
      if (r.start < lastEnd) continue;
      accepted.add(r);
      lastEnd = r.end;
    }

    final result = <ParselyElement>[];
    for (final r in accepted) {
      final base = ParselyElement(
        type: r.type,
        parsed: r.parsed,
        start: r.start,
        end: r.end,
        displayText: r.parsed,
      );
      if (options.validator != null && !options.validator!(base)) continue;

      String? display;
      if (maskBuilder != null) display = maskBuilder(base);
      if (display == null && masks != null) display = masks.resolve(base);
      if (display == null && masks != null && masks.masksType(r.type)) {
        display = ParselyMasks.defaultMaskFor(r.type);
      }
      // ignore: deprecated_member_use_from_same_package
      if (display == null && mask != null) display = mask.resolve(r.parsed);
      display ??= ParselyHumanize.apply(base, options);

      result.add(base.copyWith(displayText: display));
    }

    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  static bool _validate(
      ParselyType type, String parsed, String text, int start, int end) {
    switch (type) {
      case ParselyType.email:
        if (parsed.contains("..")) return false;
        final domain = parsed.split("@").last;
        return domain.contains(".");
      case ParselyType.link:
        if (parsed == "mailto:" || parsed.endsWith(":")) return false;
        if (!parsed.contains(".")) return false;
        final tld = parsed.split("/").first.split(".").last.split(":").first;
        if (tld.length < 2) return false;
        return true;
      case ParselyType.phone:
        final digits = parsed.replaceAll(RegExp(r"\D"), "");
        if (digits.length < 7 || digits.length > 15) return false;
        if (_datePattern.hasMatch(parsed)) return false;
        if (RegExp(r"^\d{4}[-\/]\d{1,2}[-\/]\d{1,2}$")
            .hasMatch(parsed.trim())) {
          return false;
        }
        if (start > 0 && RegExp(r"\d").hasMatch(text[start - 1])) {
          return false;
        }
        if (end < text.length && RegExp(r"\d").hasMatch(text[end])) {
          return false;
        }
        return true;
      case ParselyType.hashTag:
        final body = parsed.substring(1);
        if (body.isEmpty) return false;
        if (RegExp(r"^\d+$", unicode: true).hasMatch(body)) return false;
        if (body == "_") return false;
        if (start > 0 && !_boundaryPrev.hasMatch(text[start - 1])) return false;
        return true;
      case ParselyType.mentionTag:
        final body = parsed.substring(1);
        if (body.isEmpty) return false;
        if (!RegExp(r"[^\d_]").hasMatch(body)) return false;
        if (start > 0 && _emailLocalChars.hasMatch(text[start - 1])) {
          return false;
        }
        if (start > 0 && !_boundaryPrev.hasMatch(text[start - 1])) return false;
        return true;
    }
  }

  /// Strip trailing sentence punctuation and unbalanced closing brackets.
  static String _trimTrailingPunctuation(String s) {
    var end = s.length;
    while (end > 0) {
      final ch = s[end - 1];
      if (".,;:!?".contains(ch)) {
        end--;
        continue;
      }
      if (ch == ")" || ch == "]" || ch == "}") {
        final open = ch == ")"
            ? "("
            : ch == "]"
                ? "["
                : "{";
        final opens = s.split(open).length - 1;
        final closes = s.split(ch).length - 1;
        if (closes > opens) {
          end--;
          continue;
        }
      }
      break;
    }
    return s.substring(0, end);
  }
}

/// Headless convenience facade (pure Dart, no Flutter imports).
class ParselyParser {
  const ParselyParser._();

  /// Extract entities from [text].
  static List<ParselyElement> extract(
    String text, {
    ParselyOptions options = const ParselyOptions(),
    ParselyMasks? masks,
    // ignore: deprecated_member_use_from_same_package
    ParselyMask? mask,
    ParselyMaskBuilder? maskBuilder,
    List<EntityRule> customRules = const [],
  }) =>
      EntityEngine.extract(
        text,
        options: options,
        masks: masks,
        // ignore: deprecated_member_use_from_same_package
        mask: mask,
        maskBuilder: maskBuilder,
        customRules: customRules,
      );

  /// Replace entities with their display text (mask-for-export).
  static String replace(
    String text, {
    ParselyOptions options = const ParselyOptions(),
    ParselyMasks? masks,
    // ignore: deprecated_member_use_from_same_package
    ParselyMask? mask,
    ParselyMaskBuilder? maskBuilder,
    List<EntityRule> customRules = const [],
  }) {
    final entities = extract(text,
        options: options,
        masks: masks,
        mask: mask,
        maskBuilder: maskBuilder,
        customRules: customRules);
    if (entities.isEmpty) return text;
    final buf = StringBuffer();
    var cursor = 0;
    for (final e in entities) {
      if (e.start < cursor) continue;
      buf.write(text.substring(cursor, e.start));
      buf.write(e.displayText);
      cursor = e.end;
    }
    if (cursor < text.length) buf.write(text.substring(cursor));
    return buf.toString();
  }

  /// Whether [text] contains an entity of [type].
  static bool contains(
    String text,
    ParselyType type, {
    ParselyOptions options = const ParselyOptions(),
  }) =>
      extract(text, options: options).any((e) => e.type == type);

  /// First entity of [type], or `null`.
  static ParselyElement? firstOfType(
    String text,
    ParselyType type, {
    ParselyOptions options = const ParselyOptions(),
  }) {
    for (final e in extract(text, options: options)) {
      if (e.type == type) return e;
    }
    return null;
  }
}
