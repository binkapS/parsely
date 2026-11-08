# Parsely Kitchen-Sink Example

Interactive demo for the `binkap_parsely` package: every public API in one
screen, toggled live without restarting the app.

## What it covers

- **MaterialApp light/dark toggle** (app-bar moon/sun button).
- **Plain / default** `Parsely` widget and a **live** variant wired to every
  toggle below.
- **`ParselyOptions` switches**: `parseEmail`, `parseLink`, `parsePhone`,
  `parseHashtag`, `parseMention`, plus `stripLinkScheme` and
  `stripMentionPrefix`.
- **Masking demo** (display-only — `parsed` is never mutated):
  none, `ParselyMasks` exact map, `maskBuilder` via
  `ParselyMaskBuilders.partialLast(type: ParselyType.phone, keepLast: 4)`.
- **Headless** `ParselyParser.extract()` output list (type, parsed →
  display, offsets, `element.uri`) plus `ParselyParser.replace()`.
- **`SelectableParsely`** section (copyable; masked spans copy display text).
- **Per-type styles**: color picker per `ParselyType` feeding `parsedStyles`.
- **RTL sample** (Arabic + LTR entities) and **unicode hashtag sample**
  (`#café`, `#日本語`, emoji).
- **Copy / launch**: `Clipboard.setData` for copy; `element.uri` is shown in
  a `SnackBar` as the launch preview. No `url_launcher` dependency — wire
  `url_launcher` yourself for real launches.

## Run

```bash
cd example
flutter pub get
flutter run        # pick a device (chrome / emulator / attached phone)
```

Other handy commands:

```bash
flutter analyze    # static analysis (must pass)
flutter test       # if you add widget tests under example/test/
```

> The demo uses a path dependency on the parent package
> (`binkap_parsely: path: ../`), so run `flutter pub get` after any change
> to `../pubspec.yaml`. Code style: `withValues()` (not `withOpacity`),
> `debugPrint` (not `print`).
