import 'package:binkap_parsely/src/data.dart';
import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/mask.dart';
import 'package:binkap_parsely/src/option.dart';
import 'package:binkap_parsely/src/type.dart';
import 'package:binkap_parsely/src/util.dart';
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
      r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)",
      caseSensitive: false);

  final RegExp _phoneRegex = RegExp(r'\+?\d[\d -]{8,12}\d');

  final RegExp _hashtagRegex = RegExp(r"(#[a-zA-Z0-9_]+)");

  final RegExp _mentionRegex = RegExp(r"(@[a-zA-Z0-9_]+)");

  final List<ParselyData> _matches = <ParselyData>[];

  final List<InlineSpan> spans = <InlineSpan>[];

  ParselyMask? mask;

  late ParselyOptions options;

  late Function(ParselyElement element) onTap;

  TextStyle? style;

  TextStyle? matchedStyle;

  int currentIndex = 0;

  InlineSpan _normalText(String text) => TextSpan(text: text, style: style);

  InlineSpan _parsedText(ParselyElement parselyElement) => TextSpan(
        text: _checkMask(parselyElement),
        style: matchedStyle,
        recognizer: TapGestureRecognizer()..onTap = () => onTap(parselyElement),
      );

  String _checkMask(ParselyElement parselyElement) {
    if (mask != null && mask!.matches.contains(parselyElement.parsed)) {
      return mask!.masks
          .elementAt(mask!.matches.indexOf(parselyElement.parsed));
    }
    return options.humanize
        ? ParselyUtil.instance.humanize(parselyElement)
        : parselyElement.parsed;
  }

  void _matchRequested() {
    // Reset matches before processing new text
    _matches.clear();

    // Parse different patterns based on the options
    if (options.parseEmail) {
      _matches.addAll(_emailRegex
          .allMatches(parse)
          .map((e) => ParselyData(
                element: ParselyElement(
                    type: ParselyType.email, parsed: e.group(0)!),
                match: e,
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
              ))
          .toList());
    }

    // Sort matches by start index to process text in order
    _matches.sort((a, b) => a.match.start.compareTo(b.match.start));
  }

  void _parseInlineSpans() {
    _matchRequested();

    // If no matches are found, just add the full text as normal
    if (_matches.isEmpty) {
      spans.add(_normalText(parse));
      return;
    }

    // Iterate over the matches
    for (ParselyData element in _matches) {
      // Add normal text before the match, if any
      if (currentIndex < element.match.start) {
        spans.add(
            _normalText(parse.substring(currentIndex, element.match.start)));
        currentIndex = element.match.end;
      }

      // Add the parsed text (email, link, etc.)
      spans.add(_parsedText(element.element));
    }

    // After the last match, if any, add the remaining normal text
    if (currentIndex < parse.length) {
      spans.add(_normalText(parse.substring(currentIndex, parse.length)));
    }
  }

  List<InlineSpan> buildInlineSpans({
    required ParselyOptions parselyOptions,
    TextStyle? textStyle,
    TextStyle? parsedStyle,
    required Function(ParselyElement element) click,
    ParselyMask? mask,
  }) {
    options = parselyOptions;
    matchedStyle = parsedStyle;
    style = textStyle;
    onTap = click;
    this.mask = mask;

    _parseInlineSpans();
    return spans;
  }
}
