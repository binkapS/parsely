import 'package:binkap_parsely/src/data.dart';
import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/option.dart';
import 'package:binkap_parsely/src/type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Parser {
  Parser({
    required this.parse,
  });

  final String parse;

  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    caseSensitive: false,
  );

  final RegExp _linkRegex = RegExp(
      r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");

  final RegExp _phoneRegex = RegExp(r'\+?\d[\d -]{8,12}\d');

  final RegExp _hashtagRegex = RegExp(r"(#[a-zA-Z0-9_]+)");

  final RegExp _mentionRegex = RegExp(r"(@[a-zA-Z0-9_]+)");

  RegExp regex = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))?[\w/\-?=%.][-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");

  final List<ParselyData> _matches = <ParselyData>[];

  final List<InlineSpan> spans = <InlineSpan>[];

  late ParselyOptions options;

  late Function(ParselyElement element) onTap;

  TextStyle? style;

  TextStyle? matchedStyle;

  int currentIndex = 0;

  InlineSpan _normalText(String text) => TextSpan(text: text, style: style);

  InlineSpan _parsedText(ParselyElement parselyElement) => TextSpan(
        text: parselyElement.parsed,
        style: matchedStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => onTap(
                parselyElement,
              ),
      );

  void _matchRequested() {
    if (options.parseEmail) {
      _matches.addAll(_emailRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element: ParselyElement(
                    type: ParselyType.email, parsed: e.group(0)!),
                match: e,
                regex: e.pattern,
              ))
          .toList());
    }
    if (options.parseLink) {
      _matches.addAll(_linkRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element:
                    ParselyElement(type: ParselyType.link, parsed: e.group(0)!),
                match: e,
                regex: e.pattern,
              ))
          .toList());
    }
    if (options.parsePhone) {
      _matches.addAll(_phoneRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element: ParselyElement(
                    type: ParselyType.phone, parsed: e.group(0)!),
                match: e,
                regex: e.pattern,
              ))
          .toList());
    }
    if (options.parseHashTag) {
      _matches.addAll(_hashtagRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element: ParselyElement(
                    type: ParselyType.hashTag, parsed: e.group(0)!),
                match: e,
                regex: e.pattern,
              ))
          .toList());
    }
    if (options.parseMentionTag) {
      _matches.addAll(_mentionRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element: ParselyElement(
                    type: ParselyType.mentionTag, parsed: e.group(0)!),
                match: e,
                regex: e.pattern,
              ))
          .toList());
    }
    _matches.sort((a, b) => a.match.start.compareTo(b.match.start));
  }

  void _parseInlineSpans() {
    _matchRequested();
    for (ParselyData element in _matches) {
      if (currentIndex < element.match.start) {
        spans.add(
            _normalText(parse.substring(currentIndex, element.match.start)));
        currentIndex = element.match.end;
      }
      spans.add(_parsedText(element.element));
    }
    spans.add(_normalText(parse.substring(currentIndex, parse.length)));
  }

  List<InlineSpan> buildInlineSpans({
    required ParselyOptions parselyOptions,
    TextStyle? textStyle,
    TextStyle? parsedStyle,
    required Function(ParselyElement element) click,
  }) {
    options = parselyOptions;
    matchedStyle = parsedStyle;
    style = textStyle;
    onTap = click;
    _parseInlineSpans();
    return spans;
  }
}
