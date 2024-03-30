import 'package:binkap_parsely/src/element.dart';
import 'package:binkap_parsely/src/type.dart';

class ParselyUtil {
  ParselyUtil._();

  static ParselyUtil instance = ParselyUtil._();

  String humanize(ParselyElement element) {
    return switch (element.type) {
      ParselyType.link => _humanizeLink(element.parsed),
      ParselyType.mentionTag => _humanizeMention(element.parsed),
      _ => element.parsed,
    };
  }

  String _humanizeLink(String link) {
    return link.replaceAll(
        RegExp(r"(www\.)?(http(s)?:\/.)?", caseSensitive: false), '');
  }

  String _humanizeMention(String mention) {
    return mention.replaceAll(RegExp(r'@'), '');
  }
}
