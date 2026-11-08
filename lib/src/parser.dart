import "package:binkap_parsely/src/data.dart";
import "package:binkap_parsely/src/element.dart";
import "package:binkap_parsely/src/engine.dart";
import "package:binkap_parsely/src/masks.dart";
import "package:binkap_parsely/src/option.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Legacy parser (kept for backward compatibility).
///
/// New code should use [ParselyParser.extract] for headless use and the
/// [Parsely] widget for display. This class now delegates to [EntityEngine]
/// and is idempotent (clears all state on every [buildInlineSpans] call).
class Parser {
  /// Creates a [Parser] for the source [parse] text.
  Parser({required this.parse});

  /// The source text to parse.
  final String parse;

  final List<ParselyData> _matches = <ParselyData>[];

  /// The built inline spans (plain and tappable entity spans).
  final List<InlineSpan> spans = <InlineSpan>[];

  /// Map-based masking configuration for display text.
  ParselyMasks? masks;

  /// Function-based masking; returns a display override or null.
  ParselyMaskBuilder? maskBuilder;

  /// Parsing and display options used by this parser.
  late ParselyOptions options;

  /// Callback invoked when a parsed entity is tapped.
  late Function(ParselyElement element) onTap;

  /// Style for non-entity (plain) text spans.
  TextStyle? style;

  /// Style for matched entity spans.
  TextStyle? matchedStyle;

  /// Current cursor offset while building spans.
  int currentIndex = 0;

  InlineSpan _normalText(String text) => TextSpan(text: text, style: style);

  InlineSpan _parsedText(ParselyElement parselyElement) => TextSpan(
        text: parselyElement.displayText,
        style: matchedStyle,
        recognizer: TapGestureRecognizer()..onTap = () => onTap(parselyElement),
      );

  void _matchRequested() {
    _matches.clear();
    spans.clear();
    currentIndex = 0;
    final entities = EntityEngine.extract(
      parse,
      options: options,
      masks: masks,
      maskBuilder: maskBuilder,
    );
    for (final e in entities) {
      _matches.add(
          ParselyData(element: e, match: _FakeMatch(parse, e.start, e.end)));
    }
  }

  void _parseInlineSpans() {
    _matchRequested();
    if (_matches.isEmpty) {
      spans.add(_normalText(parse));
      return;
    }
    for (final element in _matches) {
      if (currentIndex > element.match.start) continue;
      if (currentIndex < element.match.start) {
        spans.add(
            _normalText(parse.substring(currentIndex, element.match.start)));
      }
      spans.add(_parsedText(element.element));
      currentIndex = element.match.end;
    }
    if (currentIndex < parse.length) {
      spans.add(_normalText(parse.substring(currentIndex, parse.length)));
    }
  }

  /// Builds and returns inline spans for [parse] using the given options.
  ///
  /// [parselyOptions] controls extraction, [textStyle] / [parsedStyle]
  /// style plain and entity spans, and [click] receives tapped elements.
  List<InlineSpan> buildInlineSpans({
    required ParselyOptions parselyOptions,
    TextStyle? textStyle,
    TextStyle? parsedStyle,
    required Function(ParselyElement element) click,
    ParselyMasks? masks,
    ParselyMaskBuilder? maskBuilder,
  }) {
    options = parselyOptions;
    matchedStyle = parsedStyle;
    style = textStyle;
    onTap = click;
    this.masks = masks;
    this.maskBuilder = maskBuilder;
    _parseInlineSpans();
    return spans;
  }

  /// Headless helper.
  static List<ParselyElement> extract(
    String text, {
    ParselyOptions options = const ParselyOptions(),
    ParselyMasks? masks,
    ParselyMaskBuilder? maskBuilder,
  }) =>
      ParselyParser.extract(
        text,
        options: options,
        masks: masks,
        maskBuilder: maskBuilder,
      );
}

/// Minimal [Match] implementation preserving start/end/input.
class _FakeMatch implements Match {
  _FakeMatch(this._input, this._start, this._end);

  final String _input;
  final int _start;
  final int _end;

  @override
  int get start => _start;

  @override
  int get end => _end;

  @override
  String get input => _input;

  @override
  int get groupCount => 0;

  @override
  Pattern get pattern => RegExp(r"");

  @override
  String? group(int group) =>
      group == 0 ? _input.substring(_start, _end) : null;

  @override
  String? operator [](int group) => this.group(group);

  @override
  List<String?> groups(List<int> groupIndices) =>
      groupIndices.map(group).toList();
}
