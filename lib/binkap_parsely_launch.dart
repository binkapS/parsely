/// Optional launch entrypoint (zero-dependency).
///
/// Parsely core has **0 dependencies**. This entrypoint re-exports the
/// [ParselyLaunch] URI helpers so you can pass results to `url_launcher`
/// (or keep them dependency-free) without pulling in the widget layer.
///
/// ```dart
/// import 'package:binkap_parsely/binkap_parsely_launch.dart';
/// onTap: (e) {
///   final uri = ParselyLaunch.uriFor(e);
///   if (uri != null) launch(url_launcher.launchUrl(uri));
/// }
/// ```
library;

export 'src/element.dart';
export 'src/launch.dart';
export 'src/type.dart';
