import "package:binkap_parsely/src/element.dart";
import "package:binkap_parsely/src/engine.dart";
import "package:binkap_parsely/src/masks.dart";
import "package:binkap_parsely/src/option.dart";
import "package:binkap_parsely/src/rule.dart";
import "package:binkap_parsely/src/type.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Selectable variant of [Parsely] (copyable text).
///
/// Uses [SelectableText.rich] with the same entity/recognizer logic.
/// Copying a masked span copies the *display* text (privacy-preserving).
class SelectableParsely extends StatefulWidget {
  /// Creates a [SelectableParsely] widget rendering [text] with selectable,
  /// tappable entities.
  ///
  /// Behaves like [Parsely] but uses [SelectableText.rich] so text can be
  /// copied. Copying a masked span copies its display text.
  const SelectableParsely({
    super.key,
    required this.text,
    this.style,
    this.parsedStyle,
    this.parsedStyles,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textScaler,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.focusNode,
    this.selectionColor,
    this.options,
    this.enabledEntities,
    this.onTap,
    this.onTapHandlers,
    this.onSelectionChanged,
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

  /// Maximum number of lines, as for [SelectableText].
  final int? maxLines;

  /// How to align the text, as for [SelectableText].
  final TextAlign textAlign;

  /// Text direction, as for [SelectableText].
  final TextDirection? textDirection;

  /// Scales text size, as for [SelectableText].
  final TextScaler? textScaler;

  /// Strut style for layout, as for [SelectableText].
  final StrutStyle? strutStyle;

  /// How to measure text width, as for [SelectableText].
  final TextWidthBasis textWidthBasis;

  /// Line height behaviour, as for [SelectableText].
  final TextHeightBehavior? textHeightBehavior;

  /// Focus node for text selection, as for [SelectableText].
  final FocusNode? focusNode;

  /// Selection highlight colour, as for [SelectableText].
  final Color? selectionColor;

  /// Parsing and display options; defaults to const [ParselyOptions].
  final ParselyOptions? options;

  /// Convenience override restricting which entity types are enabled.
  final Set<ParselyType>? enabledEntities;

  /// Called when any parsed entity is tapped, with the tapped element.
  final ValueChanged<ParselyElement>? onTap;

  /// Per-type tap handlers, invoked before [onTap] for the matching type.
  final Map<ParselyType, ValueChanged<ParselyElement>>? onTapHandlers;

  /// Called when the text selection changes, as for [SelectableText].
  final SelectionChangedCallback? onSelectionChanged;

  /// Map-based masking configuration for display text.
  final ParselyMasks? masks;

  /// Function-based masking; returns a display override or null.
  final ParselyMaskBuilder? maskBuilder;

  /// Additional custom entity rules to recognize.
  final List<EntityRule> customRules;

  @override
  State<SelectableParsely> createState() => _SelectableParselyState();
}

class _SelectableParselyState extends State<SelectableParsely> {
  List<InlineSpan> _spans = const [];
  List<TapGestureRecognizer> _recognizers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuild();
  }

  @override
  void didUpdateWidget(SelectableParsely oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.options != widget.options ||
        oldWidget.masks != widget.masks ||
        oldWidget.parsedStyle != widget.parsedStyle) {
      _rebuild();
    }
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
      }
      final style = widget.parsedStyles?[e.type] ??
          widget.parsedStyle ??
          _themeFallback(context);
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
        semanticsLabel: _semantic(e),
      ));
      cursor = e.end;
    }
    if (cursor < widget.text.length) {
      children.add(
          TextSpan(text: widget.text.substring(cursor), style: widget.style));
    }
    _spans = children;
  }

  TextStyle _themeFallback(BuildContext context) =>
      TextStyle(color: Theme.of(context).colorScheme.primary);

  String _semantic(ParselyElement e) => switch (e.type) {
        ParselyType.link => "Link: ${e.displayText}",
        ParselyType.email => "Email address: ${e.displayText}",
        ParselyType.phone => "Phone number: ${e.displayText}",
        ParselyType.hashTag => "Hashtag: ${e.displayText}",
        ParselyType.mentionTag => "Mention: ${e.displayText}",
      };

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: _spans),
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textScaler: widget.textScaler ?? MediaQuery.textScalerOf(context),
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
      onSelectionChanged: widget.onSelectionChanged,
    );
  }
}
