import "package:binkap_parsely/src/element.dart";

/// Zero-dependency launch helpers.
///
/// Parsely intentionally has **0 dependencies**. Use these helpers to build
/// a [Uri] for any entity and hand it to `url_launcher` (or any launcher) in
/// your app:
///
/// ```dart
/// import 'package:url_launcher/url_launcher.dart';
/// onLinkTap: (e) async {
///   final uri = e.uri ?? ParselyLaunch.uriFor(e);
///   if (uri != null) await launchUrl(uri);
/// }
/// ```
class ParselyLaunch {
  const ParselyLaunch._();

  /// Returns a launchable [Uri] for [element], or `null`.
  static Uri? uriFor(ParselyElement element) => element.uri;

  /// Returns `mailto:` / `tel:` / `https://` scheme string.
  static String? schemeFor(ParselyElement element) => element.uri?.scheme;

  /// Convenience label for the entity (display text).
  static String labelFor(ParselyElement element) => element.displayText;
}
