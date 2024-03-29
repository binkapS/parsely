import 'package:binkap_parsely/src/element.dart';

class ParselyData {
  ParselyData({
    required this.element,
    required this.match,
    required this.regex,
  });
  final ParselyElement element;
  final RegExp regex;
  final Match match;
}
