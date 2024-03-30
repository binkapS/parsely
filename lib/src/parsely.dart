import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/mask.dart';
import 'package:binkap_parsely/src/option.dart';
import 'package:binkap_parsely/src/parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Parsely extends StatelessWidget {
  const Parsely({
    super.key,
    required this.text,
    this.style,
    this.parsedStyle,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaler = TextScaler.noScaling,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
    this.options,
    required this.onTap,
    this.mask,
  });

  final String text;

  final TextStyle? style;

  final TextStyle? parsedStyle;

  final int? maxLines;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final bool softWrap;

  final TextOverflow overflow;

  final TextScaler textScaler;

  final Locale? locale;

  final StrutStyle? strutStyle;

  final TextWidthBasis textWidthBasis;

  final TextHeightBehavior? textHeightBehavior;

  final SelectionRegistrar? selectionRegistrar;

  final Color? selectionColor;

  final ParselyOptions? options;

  final Function(ParselyElement element) onTap;

  final ParselyMask? mask;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: Parser(parse: text).buildInlineSpans(
          parselyOptions: options ?? ParselyOptions(),
          textStyle: style,
          parsedStyle: parsedStyle ??
              const TextStyle(
                color: Colors.blue,
              ),
          click: onTap,
          mask: mask,
        ),
      ),
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionRegistrar: selectionRegistrar,
      selectionColor: selectionColor,
    );
  }
}
