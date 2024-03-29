class ParselyOptions {
  ParselyOptions({
    this.humanize = true,
    this.parseEmail = true,
    this.parseHashTag = true,
    this.parseLink = true,
    this.parsePhone = true,
    this.parseMentionTag = true,
  });

  /// hide https://, http:// and www
  final bool humanize;

  final bool parseEmail;

  final bool parsePhone;

  final bool parseLink;

  final bool parseHashTag;

  final bool parseMentionTag;
}
