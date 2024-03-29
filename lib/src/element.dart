import 'package:binkap_parsely/src/type.dart';

class ParselyElement {
  ParselyElement({
    required this.type,
    required this.parsed,
  });

  final ParselyType type;

  final String parsed;
}
