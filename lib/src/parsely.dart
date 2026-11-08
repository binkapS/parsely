import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/engine.dart';
import 'package:binkap_parsely/src/masks.dart';
import 'package:binkap_parsely/src/option.dart';
import 'package:binkap_parsely/src/rule.dart';
import 'package:binkap_parsely/src/type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders [text] with tappable links, emails, phones, hashtags and mentions.
///
/// ```dart
/// Parsely(
///   text: 'Hello @dartlang, visit https://dart.dev',
///   onTap: (e) => debugPrint('${e.type}: ${e.parsed} (${e.start}-${e.end})'),
/// )
/// ```
///
/// Display masking is **display-only**: [ParselyElement.parsed] (the payload
/// delivered to [onTap]) still holds the original value. See README §11.3.
///
/// Owns its [TapGestureRecognizer]s — they are disposed in `dispose()` and
/// when the text/options change.
class Parsely extends StatefulWidget {
  /// Creates a [Parsely] widget rendering [text] with tappable entities.
  ///
  /// Entities are styled with [parsedStyle] / [parsedStyles] and reported
  /// via [onTap] / [onTapHandlers]. Display can be masked via [masks] /
  /// [maskBuilder] without changing the [ParselyElement.parsed] payload.
  const Parsely({
    super.key,
    required this.text,
    this.style,
    this.parsedStyle,
    this.parsedStyles,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaler,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
    this.options,
    this.enabledEntities,
    this.onTap,
    this.onTapHandlers,
    this.masks,
    this.maskBuilder,
    this.customRules = const [],
  });

  /// The plain source text to parse and render.
  final String text;

  /// Style for non-entity (plain) text spans.
  final TextStyle? style;

  /// Style for parsed entity spans (overridden per-type by [parsedStyles]).
  final TextStyle? parsedStyle;

  /// Per-[ParselyType] styles for parsed entity spans.
  final Map<ParselyType, TextStyle>? parsedStyles;

  /// Maximum number of lines, as for [RichText].
  final int? maxLines;

  /// How to align the text, as for [RichText].
  final TextAlign textAlign;

  /// Text direction, as for [RichText].
  final TextDirection? textDirection;

  /// Whether text wraps at soft line breaks, as for [RichText].
  final bool softWrap;

  /// How overflow text is handled, as for [RichText].
  final TextOverflow overflow;

  /// Scales text size, as for [RichText].
  final TextScaler? textScaler;

  /// Locale for text layout, as for [RichText].
  final Locale? locale;

  /// Strut style for layout, as for [RichText].
  final StrutStyle? strutStyle;

  /// How to measure text width, as for [RichText].
  final TextWidthBasis textWidthBasis;

  /// Line height behaviour, as for [RichText].
  final TextHeightBehavior? textHeightBehavior;

  /// Registrar for selectable text, as for [RichText].
  final SelectionRegistrar? selectionRegistrar;

  /// Selection highlight colour, as for [RichText].
  final Color? selectionColor;

  /// Parsing and display options; defaults to const [ParselyOptions].
  final ParselyOptions? options;

  /// Convenience override restricting which entity types are enabled.
  final Set<ParselyType>? enabledEntities;

  /// Called when any parsed entity is tapped, with the tapped element.
  final ValueChanged<ParselyElement>? onTap;

  /// Per-type tap handlers, invoked before [onTap] for the matching type.
  final Map<ParselyType, ValueChanged<ParselyElement>>? onTapHandlers;

  /// Map-based masking configuration for display text.
  final ParselyMasks? masks;

  /// Function-based masking; returns a display override or null.
  final ParselyMaskBuilder? maskBuilder;

  /// Additional custom entity rules to recognize.
  final List<EntityRule> customRules;

  @override
  State<Parsely> createState() => _ParselyState();
}

class _ParselyState extends State<Parsely> {
  List<InlineSpan> _spans = const [];
  List<TapGestureRecognizer> _recognizers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuild();
  }

  @override
  void didUpdateWidget(Parsely oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inputsChanged(oldWidget)) _rebuild();
  }

  bool _inputsChanged(Parsely old) {
    return old.text != widget.text ||
        old.options != widget.options ||
        old.masks != widget.masks ||
        old.maskBuilder != widget.maskBuilder ||
        old.parsedStyle != widget.parsedStyle ||
        old.parsedStyles != widget.parsedStyles ||
        old.style != widget.style ||
        old.enabledEntities != widget.enabledEntities;
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers = [];
  }

  void _rebuild() {
    _disposeRecognizers();
    final options = widget.options ?? const ParselyOptions();
    final effectiveOptions = widget.enabledEntities != null
        ? options.copyWith(enabledEntities: widget.enabledEntities)
        : options;

    final entities = EntityEngine.extract(
      widget.text,
      options: effectiveOptions,
      masks: widget.masks,
      maskBuilder: widget.maskBuilder,
      customRules: widget.customRules,
    );

    final children = <InlineSpan>[];
    var cursor = 0;
    for (final e in entities) {
      if (e.start > cursor) {
        children.add(TextSpan(
            text: widget.text.substring(cursor, e.start), style: widget.style));
      } else if (e.start < cursor) {
        continue;
      }
      final style = widget.parsedStyles?[e.type] ??
          widget.parsedStyle ??
          _themeFallbackStyle(context);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          widget.onTapHandlers?[e.type]?.call(e);
          widget.onTap?.call(e);
        };
      _recognizers.add(recognizer);
      children.add(TextSpan(
        text: e.displayText,
        style: style,
        recognizer: recognizer,
        semanticsLabel: _semanticLabelFor(e),
      ));
      cursor = e.end;
    }
    if (cursor < widget.text.length) {
      children.add(
          TextSpan(text: widget.text.substring(cursor), style: widget.style));
    }
    _spans = children;
  }

  TextStyle _themeFallbackStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(color: theme.colorScheme.primary);
  }

  String _semanticLabelFor(ParselyElement e) {
    return switch (e.type) {
      ParselyType.link => 'Link: ${e.displayText}',
      ParselyType.email => 'Email address: ${e.displayText}',
      ParselyType.phone => 'Phone number: ${e.displayText}',
      ParselyType.hashTag => 'Hashtag: ${e.displayText}',
      ParselyType.mentionTag => 'Mention: ${e.displayText}',
    };
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-default theme fallback when context is available (initState has none).
    // Keep cached spans; only rebuild is needed when style depends on theme.
    return RichText(
      text: TextSpan(children: _spans),
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      textScaler: widget.textScaler ?? MediaQuery.textScalerOf(context),
      locale: widget.locale,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionRegistrar: widget.selectionRegistrar,
      selectionColor: widget.selectionColor,
    );
  }
}

/// Alias so downstream code can reference the pure-Dart regexes without importing internals.
class ParselyRegexesAlias {
  const ParselyRegexesAlias._();
}
