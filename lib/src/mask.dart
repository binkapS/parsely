class ParselyMask {
  ParselyMask({
    required this.matches,
    required this.masks,
  }) : assert(matches.length == masks.length);
  final List<String> matches;

  final List<String> masks;
}
