/// Pure-Dart entrypoint (no Flutter imports).
///
/// Use for search indexing, analytics, masking and server-side use.
/// ```dart
/// import 'package:binkap_parsely/parser.dart';
/// final entities = ParselyParser.extract('Mail a@b.com');
/// ```
library;

export 'src/element.dart';
export 'src/engine.dart';
export 'src/humanize.dart';
export 'src/launch.dart';
export 'src/masks.dart';
export 'src/option.dart';
export 'src/regexes.dart';
export 'src/rule.dart';
export 'src/type.dart';
