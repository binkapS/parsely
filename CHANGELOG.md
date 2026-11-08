# Changelog

All notable changes to Parsely will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-11-08

### Breaking changes

- `stripLinkScheme` and `stripMentionPrefix` default to `false` (display no
  longer strips link schemes or mention prefixes unless you opt in).
  Previously the combined `humanize: true` default stripped both.

### Removed

- Removed deprecated `ParselyOptions(humanize: …)`. Migrate:
  `humanize: true` → `stripLinkScheme: true, stripMentionPrefix: true`;
  `humanize: false` → `stripLinkScheme: false, stripMentionPrefix: false`.
- Removed deprecated `parseHashTag` / `parseMentionTag` options. Use
  `parseHashtag` / `parseMention`.
- Removed deprecated `ParselyMask(matches:…, masks:…)` class and every
  `mask:` parameter (`Parsely`, `SelectableParsely`, `ParselyParser`,
  `EntityEngine`, `Parser`). Use `ParselyMasks(exact: {…})` or a
  `ParselyMaskBuilder` function; `ParselyMask.toMasks()` no longer exists.
- Removed deprecated `ParselyUtil` singleton. Use `ParselyHumanize` helpers
  (`stripLinkScheme`, `stripMentionPrefix`, `apply`).
- Removed `lib/src/mask.dart` and `lib/src/util.dart` exports from the
  `binkap_parsely` and `parser` entrypoints.

### Changed

- `ParselyOptions.humanize` fallback removed: `stripLinkScheme` /
  `stripMentionPrefix` are now plain `bool` flags (default `false`), not
  nullable. `effectiveStripLinkScheme` / `effectiveStripMentionPrefix`
  return them directly.
- `ParselyOptions.copyWith` / equality / `hashCode` / `toString` no longer
  reference `humanize` or the `*Tag` aliases.

## [0.1.0] - 2026-11-08

### Added

- Public API surface: `Parsely`, `SelectableParsely`, `ParselyOptions`, `ParselyElement`, `ParselyType`, `ParselyParser`, `ParselyLaunch`, `ParselyMasks`, `ParselyMaskBuilder`, `ParselyMaskBuilders`, `EntityRule`, `ParselyRegexes`, `ParselyHumanize` (with `stripLinkScheme` / `stripMentionPrefix`).
- New option names `parseHashtag` / `parseMention` and granular display flags `stripLinkScheme` / `stripMentionPrefix`; legacy `parseHashTag` / `parseMentionTag` kept as deprecated.
- Map-based masking: `ParselyMasks(exact: …, patterns: …, maskAll: …)` and function form `ParselyMaskBuilder`; legacy `ParselyMask(matches: …, masks: …)` kept as deprecated with `toMasks()` converter.
- Headless extraction API `ParselyParser.extract/replace/contains/firstOfType`.
- `ParselyElement` fields `displayText`, `start`, `end`, `resolvedEnd`, and launchable `uri` (`https://`, `mailto:`, `tel:`).
- Per-type styling via `parsedStyles`, per-type tap handlers via `onTapHandlers`, entity gating via `enabledEntities`, post-match `validator`, and custom rules via `customRules`.

### Changed

- Overlap precedence fixed to `email > link > phone > hashtag > mention` with deterministic, non-overlapping, in-order spans.
- Minimum Flutter requirement raised to `>=3.22.0` (real floor for `TextScaler`).
- Dev dependency `flutter_lints` bumped from `^3.0.0` to `^6.0.0`; analyzer now enforces `public_member_api_docs` and `prefer_final_locals`.

### Fixed

- Fixed `ParselyOptions` leading-space typo in `pubspec.yaml` description.
- Fixed legacy `Parser` state leak by clearing matches/spans on every `buildInlineSpans` call (idempotent).
- Fixed trailing-punctuation / bracket handling for links and emails, and phone / hashtag / mention boundary validation (no date / numeric-emoji false positives).

### Documentation

- README restructured: badges, TOC, getting started, full compilable example, API reference tables, `I want to…` recipes, privacy & masking note, troubleshooting, migration guide, and out-of-scope section.
- `CONTRIBUTING.md` completed (setup, checks, PR conventions, issue expectations, code of conduct, how to add a new entity type end-to-end).
- `LICENSE` year/holder set to `Copyright (c) 2026 Binkap S` (MIT).

## [0.0.1] - 2026-11-08

- Initial Build and Release.
