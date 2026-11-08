# Parsely — Roadmap & Improvement Plan

> **Package:** `binkap_parsely` (pub.dev) · **Repo:** `binkapS/binkap_parsely`
> **Current version:** `0.0.1` (pre-1.0) · **Audited:** 2026-11-08 · **Auditor:** automated review of full source (`lib/` 358 LOC, `example/`, config, docs, git history)
> **Goal of this document:** a single, ordered, actionable backlog to take Parsely from a working demo to a polished, pub.dev-ready `1.0.0`. It is an *audit + proposal*, not a changelog. Items are marked **P0 (fix) / P1 (polish) / P2 (future)** with impact/effort so you can execute top-down without re-reading the code.

```text
Status key:  [ ] todo   [~] decision needed   [x] done
Effort:      S ≤1d · M 2-5d · L ≥1wk   ·   Risk: Low/Med/High (breaking-change risk)
```

---

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [Current-state inventory](#2-current-state-inventory)
3. [P0 Correctness bugs — fix before anything else](#3-p0-correctness-bugs--fix-before-anything-else)
4. [Parser & regex overhaul](#4-parser--regex-overhaul)
5. [Widget API redesign (breaking-change candidates)](#5-widget-api-redesign-breaking-change-candidates)
6. [Performance, memory & lifecycle](#6-performance-memory--lifecycle)
7. [Accessibility, i18n & UX](#7-accessibility-i18n--ux)
8. [Headless / non-widget API](#8-headless--non-widget-api)
9. [Testing strategy](#9-testing-strategy)
10. [Example app](#10-example-app)
11. [Documentation & pub.dev hygiene](#11-documentation--pubdev-hygiene)
12. [Packaging, CI/CD & community](#12-packaging-cicd--community)
13. [Architecture refactoring](#13-architecture-refactoring)
14. [Feature roadmap by release](#14-feature-roadmap-by-release)
15. [Migration guide (planned breaking changes)](#15-migration-guide-planned-breaking-changes)
16. [Prioritized backlog (master table)](#16-prioritized-backlog-master-table)
17. [Open questions / decisions needed](#17-open-questions--decisions-needed)
18. [Definition of done](#18-definition-of-done)
19. [Appendix A — regex reference & test corpus](#appendix-a--regex-reference--test-corpus)
20. [Appendix B — target file tree & API sketch](#appendix-b--target-file-tree--api-sketch)

---

## 1. Executive summary

Parsely is a small, focused Flutter package: given a `String`, it detects **links, emails, phone numbers, hashtags and @mentions**, renders them as tappable `RichText` spans with a distinct style, optionally humanizes display text (strip scheme / `@`), and optionally masks specific values (display replacement). The integration surface is one widget (`Parsely`), one options class (`ParselyOptions`), one mask class (`ParselyMask`), one element model (`ParselyElement`), one enum (`ParselyType`).

The idea is sound and the public API is easy to learn. The problems are all in the details:

| Dimension | Verdict today |
|---|---|
| **Correctness of parsing** | ❌ Two blocking bugs: embedded emails never match (anchored `^…$` regex), and the span-builder loses/duplicates text whenever a match is at offset 0 or matches overlap. The widget corrupts real-world input like `email@x.com` (double-counted as email *and* mention). |
| **Correctness of lifecycle** | ❌ Every span creates a `TapGestureRecognizer` that is never disposed. In a `StatelessWidget` that is an unfixable leak. |
| **Completeness** | ❌ No tests (`test/` absent), no headless API, no selectable-text variant, no built-in link launching (example only `print`s). |
| **Runnable example** | ❌ `example/pubspec.yaml` is missing, so the example cannot `pub get` / run as committed. Verified: `flutter analyze` passes on `lib/`, fails on `example/` until `pub get` is run. |
| **pub.dev readiness** | ❌ No `repository`, `topics`, `screenshots`; no dartdoc comments; README has placeholders/broken sections; CHANGELOG is one line; CONTRIBUTING is truncated at the clone step. |
| **API design debt** | ⚠️ Parallel-list `ParselyMask`, vague `humanize` flag, inconsistent `Tag` capitalization, required `onTap` (forces callers who want plain text to pass a no-op), hardcoded blue `parsedStyle`, `textScaler: noScaling` breaks a11y. |
| **Regex quality** | ⚠️ Link TLD capped at 6 chars and 256-char domain, phone regex over/under-matches, hashtag/mention allow numeric-only and lack unicode/boundary guards. |

**Bottom line:** P0 bug fixes + a test suite unlock everything else. The 2-day “stabilize” milestone (Milestone 1 below) makes the package safe to use; the rest is growth to pub.dev “Popular” tier.

---

## 2. Current-state inventory

### 2.1 Repository layout (as audited)

```text
.
├── CHANGELOG.md          # 3 lines — only 0.0.1 Initial Build and Release
├── CONTRIBUTING.md       # 13 lines — truncated mid-instructions
├── LICENSE               # MIT, copyright (c) Binkap S (no year)
├── README.md             # 149 lines — good structure, some gaps (see §11)
├── analysis_options.yaml # include: flutter_lints only
├── .metadata             # standard Flutter metadata, stable/jan-2024-ish rev
├── pubspec.yaml          # see §2.2
├── example/
│   ├── .gitignore        # "* / !lib" — hides platform folders & pubspec from git!
│   └── lib/main.dart     # 112 lines, single-screen demo
└── lib/                  # 358 lines total across 8 files
    ├── binkap_parsely.dart   # barrel — exports 5 of 8 files (parser/util/data hidden)
    └── src/
        ├── parsely.dart      # Parsely StatelessWidget (RichText passthrough)
        ├── parser.dart       # Parser — regex matching + InlineSpan building (170 LOC)
        ├── element.dart      # ParselyElement {type, parsed}
        ├── type.dart         # ParselyType enum (5 values)
        ├── option.dart       # ParselyOptions (6 bools)
        ├── mask.dart         # ParselyMask parallel lists
        ├── data.dart         # ParselyData {element, match} (internal)
        └── util.dart         # ParselyUtil singleton — humanize()
```

Git history (5 commits): `first commit → humanzing & masking → Update parser.dart (removed forgotten regex) → documentation → bug fix`. No branches, no tags, no CI.

### 2.2 `pubspec.yaml` as-is

| Field | Value | Issue |
|---|---|---|
| `name` | `binkap_parsely` | OK (prefixed to avoid collision with other “parsely”) |
| `description` | ` A Flutter package…` | ⚠️ Leading space = typo, wastes pub.dev search snippet |
| `version` | `0.0.1` | OK pre-1.0, but plan below assumes next = `0.1.0` |
| `homepage` | `https://binkap.com` | ⚠️ Points to company homepage, not the package. Should be repo URL |
| `repository` / `issue_tracker` | *(absent)* | ❌ pub.dev penalizes; enables “View source” button |
| `topics`, `screenshots`, `funding` | *(absent)* | ❌ discoverability |
| `environment.sdk` | `>=3.3.1 <4.0.0` | OK |
| `environment.flutter` | `>=1.17.0` | ❌ **Misleading.** Code uses `TextScaler` (Flutter ≥3.13) and `switch` expressions (Dart ≥3.0). Real floor is ~Flutter 3.22+ / Dart 3.4+. Set correctly to avoid broken installs |
| `dependencies` | `flutter` only | OK — zero deps is a selling point; keep it unless link-launching is adopted (see §14) |
| `dev_dependencies` | `flutter_test`, `flutter_lints ^3.0.0` | ⚠️ `flutter_lints` 3.0 is behind current (6.x); bump |

### 2.3 Public API surface (today)

```dart
Parsely({  required String text,
           TextStyle? style, TextStyle? parsedStyle, // default: blue
           TextAlign textAlign = start, int? maxLines, ... // full Text passthrough
           ParselyOptions? options, ParselyMask? mask,
           required Function(ParselyElement) onTap })   // required — see §5
ParselyOptions({ humanize, parseEmail, parseHashTag, parseLink, parsePhone, parseMentionTag = true })
ParselyMask({ required List<String> matches, required List<String> masks }) // parallel lists
ParselyElement({ required ParselyType type, required String parsed })
enum ParselyType { link, email, phone, hashTag, mentionTag }
```

---

## 3. P0 Correctness bugs — fix before anything else

These are not “nice to have”. Each produces **wrong output on ordinary input** today.

### 3.1 ❌ Anchored email regex never matches embedded emails — `parser.dart:17-20`

```dart
final RegExp _emailRegex = RegExp(
  r"^[a-zA-Z0-9...]+@[a-zA-Z0-9]...*$", // ^…$ anchors
);
```

*Effect:* `"Contact me at a@b.com!"` produces **zero** email matches because the whole string must be the email. Only a `text` that *is* exactly one email works.
*Fix:* remove `^`/`$` anchors, add a trailing boundary that does not consume a sentence-final `.` (see Appendix A). Add a regression test: email embedded in a sentence must match.

### 3.2 ❌ Span builder corrupts text at offset 0 and on overlap — `parser.dart:126-152`

```dart
for (ParselyData element in _matches) {
  if (currentIndex < element.match.start) {
    spans.add(_normalText(parse.substring(currentIndex, element.match.start)));
    currentIndex = element.match.end;   // ← only inside the if!
  }
  spans.add(_parsedText(element.element)); // ← always
}
```

Two distinct defects:

1. **Match at offset 0 never advances `currentIndex`.** With text starting with a hashtag (`"#hi there"`): first iteration adds the parsed span but `currentIndex` stays `0`. The trailing-text logic then re-adds `substring(0…)` → the hashtag text is **duplicated** on screen.
2. **Overlapping matches are not resolved** (`_matches` sorted only by `start`). Any text containing both an email and a mention (`foo@bar.com` → email span + `@bar` mention span overlapping) or a link containing `@` / a phone inside a link, emits **overlapping/duplicate spans**. The gap-check partially masks the duplication but still appends the parsed span for text already consumed.

*Fix (minimum):* always advance `currentIndex = element.match.end` after emitting a span, and skip matches whose `start < currentIndex` (already consumed). Ship with the overlap-resolution strategy in §4.3 (priority: email/link > phone > hashtag/mention — decide and document).

Required regression inputs: (a) entity at position 0, (b) two adjacent entities separated by one space, (c) `user@example.com` (email+mention overlap), (d) `https://x.com/@user` (link+mention), (e) entity at very end of string, (f) no matches, (g) empty string, (h) matches-only string.

### 3.3 ❌ `TapGestureRecognizer` leak — `parser.dart:50-54` + `parsely.dart:8`

Every parsed span creates `TapGestureRecognizer()..onTap = …` and nothing ever disposes it. In `StatelessWidget` this cannot be fixed — **`Parsely` must become a `StatefulWidget`** that owns a list of recognizers and disposes them in `dispose()`. This is also a rebuild storm: every rebuild creates N new recognizers.

*Fix:* convert to `StatefulWidget`; cache spans/recognizers; dispose in `dispose()` and whenever spans are rebuilt. (Alternative considered and rejected: attaching recognizers to generated `WidgetSpan`s — same disposal duty.) See §6.

### 3.4 ❌ `humanize` link regex is wrong — `util.dart:17-20`

```dart
link.replaceAll(RegExp(r"(www\.)?(http(s)?:\/.)?", caseSensitive: false), '');
```

The final `.` is **unescaped** (matches *any* char) and the group is optional, so the pattern matches partial junk (e.g. `http:/a`). It also strips `www.` *inside a path* (e.g. `https://x.com/www.page`). Result works for the happy path by accident.
*Fix:* `RegExp(r'^(https?://)?(www\.)?', caseSensitive: false)` anchored at start, replace prefix only once. Document that `humanize` is display-only: `onTap` still receives the original `parsed` value.

### 3.5 ❌ Mask parallel-list API is fragile — `mask.dart`

`matches`/`masks` are two lists correlated by index. In release mode the `assert` is stripped, so a length mismatch reaches `mask!.masks.elementAt(indexOf(…))` and throws a bare `RangeError` at runtime. Lookup is `contains()` + `indexOf()` (O(n) per element) and matching is exact/case-sensitive only — no “mask all phones”, no regex, no partial masking (`****1234`).
*Fix:* replace with `Map<String,String>` (or a `String Function(ParselyElement)?` callback) — breaking change, see §5.4 + §15 migration. Keep the O(n) lookup off the hot path.

### 3.6 ⚠️ Parser state is retained and re-entrant — `parser.dart:32-46`

`spans`, `_matches`, `currentIndex` are instance state; `_matches` is cleared but `spans` is not. Today `buildInlineSpans` is only called once per fresh `Parser`, so it works — but any reuse (e.g. after the §6 memoization refactor) silently duplicates spans. Make `buildInlineSpans` idempotent: clear all state at entry, or better, make the parser stateless/immutable. Compile regexes as `static final` (currently re-created per `Parser()` — wasteful).

---

## 4. Parser & regex overhaul

### 4.1 Per-entity regex upgrades (summary — full reference in Appendix A)

| Entity | Today's problem | Proposed direction |
|---|---|---|
| **Email** | Anchored `^…$`; also requires full domain? Actually allows single-label domains (`a@b`) and no trimming of trailing punctuation | Unanchored, trailing-punctuation trim, optional subdomain validation, case-insensitive. Consider using `Uri.parse` sanity-check after regex match |
| **Link** | TLD `\. [a-z]{2,6}` misses `.technology`, `.international`, IDN (punycode/unicode); domain `{2,256}` rejects short domains; `http(s)?:\/\/` — the `.` after `//` is unescaped? (in class: `(http(s)?:\/\/.` — unescaped dot = any char); matches bare `www.foo` but also matches inside words; no port/query/fragment precision | `\.(?:[a-z]{2,}|xn--[a-z0-9-]+)` (2+ or punycode), escaped literal dots, optional `www.`, balanced-paren-aware trailing trim (Wikipedia URLs), optional port, optional path/query/fragment. Validate candidate with `Uri.tryParse` |
| **Phone** | `\+?\d[\d -]{8,12}\d` (10–14 chars) — matches credit-card numbers, dates, order IDs; misses `(080) …`, `+234 (0)80…`, dots separators, extensions | Allow `()`, `.`, `/` separators and extension `ext.123` *optionally*; min/max digit-count guard (7–15 per E.164); optional libphonenumber-style validation hook (opt-in, not a hard dep); avoid matching inside a longer digit run (negative lookarounds for `\d`) |
| **Hashtag / mention** | `#[a-z0-9_]+` allows `#123`, `#1`, no unicode (`#مرحبا`, `#中文` break), no word-boundary guard (`a#b` matches), no max length | Require ≥1 letter/underscore (`(?=[^\d_]*[_a-zA-Z…])[\w…]+`), unicode-aware (`\p{L}` with `unicode: true`), preceding-boundary lookbehind `(?:^|(?<=[\s(])`, optional min-length. Email-tail guard: mention must not be preceded by email-local chars |
| **All** | Priority/overlap undefined; sort by start only | Deterministic priority order + overlap resolution (§4.3); configurable via options |

### 4.2 Trimming & boundary rules (decide once, test everywhere)

Sentence punctuation must not be swallowed: `"Visit https://x.com."` / `"Mail a@b.com,"` / `"(#tag)"`. Implement a shared `_trimTrailingPunctuation(match)` that strips `.,;:!?` plus unbalanced `)`/`]`/`}`. Apply to link and email (and phone trailing spaces/dashes). Document the rule in README.

### 4.3 Overlap resolution & priority

Adopt this precedence (rationale: most specific/structured first):

```text
email  >  link  >  phone  >  hashtag  >  mention
```

Algorithm: sort by `(start asc, length desc, priority asc)`, then greedily accept a match only if `start >= lastAccepted.end`; otherwise skip it. This guarantees non-overlapping, in-order spans and removes the duplicate-text class of bugs in §3.2 entirely. Add an option `onOverlap: (a, b) => …`? — **No**: keep it simple, but document the table. Optionally allow `ParselyOptions.enabledEntities: Set<ParselyType>` as a cleaner alternative to 5 bools (see §5.2).

### 4.4 `humanize` / display transforms

- Rename/scope: `humanize` → granular flags (`stripLinkScheme`, `stripMentionPrefix`) or a single `displayBuilder: String Function(ParselyElement)?`. Rationale: stripping `@` from a mention changes meaning and is surprising; stripping `https://` from a link is not. Today `humanize=true` does *both*.
- Keep backward compat: `humanize: true` maps to `stripLinkScheme: true, stripMentionPrefix: false`? — **Decision needed** (§17). Document that display text ≠ parsed payload, and `onTap` receives the *original* value.
- Add `partialMask` display (e.g. `+234****9116` built-in helper `ParselyMask.partial(keepLast: 4, char: '•')`) — the most common privacy UX in chat apps.

### 4.5 Validation hooks (opt-in)

Expose `bool Function(ParselyElement)? isValidEmail/…`? Or a single `validator: bool Function(ParselyElement)` consulted after regex match. Cheap to add, solves the “phone regex matched a 13-digit card number” false-positive class without pulling in `google_phone_number_validation`.

---

## 5. Widget API redesign (breaking-change candidates)

> Principle: **group breaking changes into one major bump** (`0.2.0` or `1.0.0`) with a published migration guide (§15). Until then, every item below is additive-only.

### 5.1 `Parsely` widget itself

- [x] **P1 — Make `onTap` optional** (`ValueChanged<ParselyElement>?`). Today `required Function(ParselyElement) onTap` forces display-only users to pass a no-op. Breaking in the *permissive* direction (existing code still compiles). Switch type from legacy `Function` to `ValueChanged<ParselyElement>` for analyzer cleanliness.
- [x] **P1 — Per-type styles & callbacks (additive).** `Map<ParselyType, TextStyle>? parsedStyles` (falls back to `parsedStyle` for all) and `Map<ParselyType, ValueChanged<ParselyElement>>?` per-type tap handlers (so a chat app can style links differently from mentions, underline only links, etc.).
- [x] **P1 — Per-type enablement as a set (additive, deprecate bools gradually).** `Set<ParselyType> enabledEntities = ParselyType.values.toSet()` in options; keep the 5 bools as deprecated shims mapping into the set for one minor version.
- [x] **P2 — `SelectableParsely`** (a `SelectableText`/`RichText` with copy support). Text selection today partially works via `selectionRegistrar` but custom recognizers fight it; a dedicated selectable widget with `onSelectionTap`/`onSelectionChanged` parity is the expected API for chat/comment use cases.
- [x] **P2 — Built-in launching (opt-in, zero-dep default).** Provide `launchUrl: Uri Function(ParselyElement)?` / an enum `TapAction { callback, launch, clipboard }`. If you adopt `url_launcher` as an *optional* dep via a second entrypoint (`binkap_parsely_launch.dart`), keep the core zero-dependency (a core feature, not a cost). Email → `mailto:`, phone → `tel:`, link → `https://…`, hashtag/mention → search URL or clipboard. Never auto-launch without opt-in.
- [ ] **P2 — Hover/long-press.** `onLongPress`, `MouseCursor` styling for link spans, tooltips/semantics labels (`"Link: example.com"`, `"Email: …"`) — `TextSpan` `semanticsLabel`/`tooltip` are free wins for a11y (see §7).
- [x] **P2 — `maxLines`/overflow for spans.** Already passthrough; add a test that ellipsis works with parsed spans and document the interaction.

### 5.2 `ParselyOptions` naming & shape

- [x] Fix capitalization inconsistency: `parseHashTag` / `parseMentionTag` → `parseHashtag` / `parseMention` (breaking rename; alias via `@deprecated` const constructor forwarding for one minor).
- [x] Replace the vague `humanize` (see §4.4).
- [x] Add `copyWith()` (and `==`/`hashCode`) — currently impossible to tweak options programmatically, and tests cannot compare options.
- [x] Add `@immutable` + `const` constructor (today non-const, no immutability annotation — const-correctness matters in `build()`).
- [x] Consider `enabledEntities: Set<ParselyType>` as the canonical toggle (see §5.1).

### 5.3 `ParselyElement`

- [x] Add `displayText` (post-mask/humanize, what the user sees) vs `parsed` (original payload) — today callers must re-derive display text.
- [x] Add `start`/`end` offsets (0-based) so callers can map a span back into the source string (needed for highlight/search-replace features).
- [x] Add value equality (`==`, `hashCode`), `toString()` (`ParselyElement(link, https://…)`), and `copyWith()`.
- [x] Consider `resolved`/`Uri` helper: `Uri? get uri` for link/email/phone (parses `mailto:`/`tel:` correctly). Saves every consumer from re-implementing it wrong.

### 5.4 `ParselyMask` → `ParselyMasks` (breaking)

Replace parallel lists with:

```dart
class ParselyMasks {
  const ParselyMasks({this.exact = const {}, this.patterns = const [], this.maskAll = const {}});
  final Map<String, String> exact;              // exact decoded value → display
  final List<(Pattern pattern, String replacement)> patterns; // RegExp keys allowed
  final Set<ParselyType> maskAll;               // mask every phone, etc.
  String? resolve(ParselyElement e);            // null → no mask
}
```

Plus a **function form** (most flexible, zero config):

```dart
typedef ParselyMaskBuilder = String? Function(ParselyElement element);
// used as: maskBuilder: (e) => e.type == phone ? '•' * 6 + e.parsed.suffix(4) : null
```

Keep the old `ParselyMask` as a deprecated converter (`ParselyMask.toMasks`) for one minor version. Migration table in §15.

### 5.5 Dartdoc & lint

- [x] `public_member_api_docs` in `analysis_options.yaml`; write `///` docs for *every* public class/field/constructor. pub.dev’s documentation score requires it; it also fixes the “dictionary” HTTP-omens in README.
- [x] Add `// ignore:`-free code; enable `prefer_final_locals`, `unnecessary_await_in_loop` etc. via `lints` (see §12).

---

## 6. Performance, memory & lifecycle

- [x] **P0 — Stateful conversion + recognizer disposal** (§3.3). Cache `List<TapGestureRecognizer>` alongside spans; dispose old set on rebuild/dispose.
- [x] **P1 — Memoize parsing.** `Parsely` rebuilds on every parent build and re-runs 5 regexes over the whole string each time. Cache the computed span list keyed by `(text, options, masks, styles, callbacks)`; recompute only when inputs change (`didUpdateWidget`). Add a `Key` documentation note: same `text` + same options = free. For feed-style apps (hundreds of `Parsely` widgets), this is the difference between 60fps and jank.
- [x] **P1 — `static final` compiled regexes** (§3.6). Dart caches `RegExp` construction; hoist to constants.
- [ ] **P2 — Large-text escape hatch.** For >~100KB strings (logs, articles), offer `ParselyParser.parseAsync` / chunked parsing or document the `Text` fallback. Not needed for 0.2.0, but the API should not block it (keep the parser pure-Dart — §13).
- [x] **P2 — `RepaintBoundary` consideration.** `RichText` already repaints cheaply; measure before adding. Publish a benchmark (see §9) so future perf claims are measurable, not marketing.
- [x] Fix `@deprecated withOpacity` in example; use `withValues()`.

---

## 7. Accessibility, i18n & UX

- [x] **A11y regression:** `textScaler = TextScaler.noScaling` (parsely.dart:19) **overrides the user's system font scaling**. Default must become the ambient `MediaQuery` scaler (i.e. accept `TextScaler? textScaler` and pass through `null` to `RichText`, which then uses the environment default).
- [x] Default `parsedStyle` is hardcoded `Colors.blue` — derive from `Theme.of(context).textTheme`/color scheme (e.g. `colorScheme.primary`, `TextDecoration.underline` opt-in) so dark-mode apps don't get blue-on-dark. Keep `parsedStyle` override.
- [x] `Semantics` labels per span: `"Link: example.com"`, `"Email address: …"`, `"Phone number: …"`. Screen-reader users currently hear raw URLs; a label + `excludeSemantics` on display masks is standard.
- [x] **Language support:** hashtags/mentions must work in **RTL/Unicode scripts** (Arabic, Hebrew, CJK, emoji tags `#🎉`). This requires `unicode: true` regexes with `\p{L}` and RTL-safe trimming — add test vectors (§9).
- [x] `SelectionRegistrar` parity: verify selectable/copy interaction with recognizers; document that masked values copy as *display* or *original* (default: display — privacy-preserving — but make it explicit, see privacy note §11.3).
- [x] Contrast: README/example recommend a `fontFamily: 'DancingScript'` that is never declared in the example — replace with a shipped font or system font in the example (§10).

---

## 8. Headless / non-widget API

Today the parser is *only* reachable through the widget (it is not even exported). Many consumers want the entities without the `RichText` (search index, analytics, server-side masking, highlight-in-`TextField`).

- [x] `ParselyParser.extract(String text, {ParselyOptions? options, ParselyMasks? masks}) → List<ParselyElement>` — pure Dart, `List<ParselyElement>` with offsets.
- [x] `ParselyParser.replace(String text, …) → String` (mask-for-display/export) and `ParselyParser.contains(text, type)` / `firstOfType` conveniences.
- [x] Export from the barrel: `export 'src/parser.dart'` (or a new `parser.dart` facade). Pure-Dart entrypoint lets the logic run in workers / server (with `dart` / `flutter test` without widget bindings).
- [x] `Stream`-based progressive parsing for very long inputs (P2, deferred).

This is also the *testability* unlock: the entire §3/§4 surface becomes unit-testable without `pumpWidget`.

---

## 9. Testing strategy

**Current state: zero tests.** `test/` does not exist; CI does not exist; pub.dev awards its “tested” points only when tests run in CI. This is the single largest pub.dev-score gap after docs.

### 9.1 Unit tests (pure parser) — `test/parser_test.dart`

Table-driven corpus per entity + cross-entity + edge cases. Minimum matrix (Appendix A has the corpus template):

- [x] Email: embedded, trailing `.`/`,`, plus-addressing, subdomains, uppercase, invalid (`a@`, `@b.com`, `a@@b.com`), IDN
- [x] Link: `http(s)`, `www.`, long TLDs, ports, query/fragment, trailing punctuation, bare domains, `mailto:` non-links, overlap with email
- [x] Phone: `+<ccc>`, `(0)`, dots/dashes/slashes, extensions, too-short/too-long, inside date/card-number (must NOT match)
- [x] Hashtag/mention: unicode, `#123` (must NOT match), `a#b` boundary, email-tail guard, min lengths
- [x] Overlap/priority: `user@example.com`, `https://x.com/@user`, `#tag@user`, phone-inside-link
- [x] Humanize/mask: scheme stripping, `@` handling, mask-by-type, partial mask, no-mask fallback
- [x] Offsets: `start`/`end` correctness for every vector

### 9.2 Widget tests — `test/parsely_test.dart`

- [x] Renders plain text (no entities); renders each entity with style; `onTap` fires with correct element (use `tester.tap(find.text(...))` + `fakeAsync`/recognizer flush)
- [x] Masked display + original payload in callback; humanized display
- [x] Golden tests for link/email/phone/hashtag/mention rows (light/dark, RTL locale)
- [x] Semantics test: labels present
- [x] Regression tests for §3.2 (offset-0, adjacent, overlap)

### 9.3 Quality gates

- [x] `flutter test` + coverage ≥ 80% on `lib/src` (lower bar initially; raise after §9.1 lands)
- [x] Property/fuzz test: regexes must never throw on random unicode input; `allMatches` on 100KB string < 100ms (benchmark in `test/benchmark_test.dart`, `skip:` in CI by default)
- [x] `flutter analyze` clean (other than the known infos); `dart format --set-exit-if-changed` in CI

---

## 10. Example app

The committed example is **not runnable**: `example/pubspec.yaml` is missing (so `flutter pub get` fails with `Target of URI doesn't exist` for both files when analysed from the root), and `example/.gitignore` contains `*` → any future `pubspec.yaml`/platform folders will be hidden from git. The demo itself is a single hardcoded string on a gradient card — enough to prove the widget exists, not enough to adopt it.

- [x] **P0 — Create `example/pubspec.yaml`** (standard `flutter create` template: `name: example`, `publish_to: none`, path dep `binkap_parsely: path: ../`, `flutter & flutter_lints` deps, material launcher icon). Verify `cd example && flutter run` works on Android/iOS/Web.
- [x] **P0 — Fix `example/.gitignore`** to the standard `flutter create` one (`.dart_tool`, `build`, `pubspec.lock` as appropriate for app — *do not* ignore `pubspec.yaml`).
- [x] Replace `withOpacity` → `withValues`, `print` → `debugPrint`/a small SnackBar log panel (also fixes the `avoid_print` infos and the `unreachable_switch_default` warning).
- [x] Make it a **kitchen-sink demo**, one section per feature, each toggled live:
  - Plain text / default styles / per-type styles (color picker per type)
  - Options toggles (switches for each entity + humanize/strip)
  - Masking demo (exact, by-type, partial) with before/after
  - `ParselyParser.extract()` output list (headless proof)
  - Selectable variant, dark/light, RTL sample string, unicode hashtag sample
  - Copy-to-clipboard / launch buttons wired to real `url_launcher` (optional dep in example only)
- [x] Fix the undeclared `fontFamily: 'DancingScript'` (either ship the font via `google_fonts` in the example or drop it).
- [x] Add `example/README.md` (run instructions) and screenshots/GIFs for the root README.

---

## 11. Documentation & pub.dev hygiene

### 11.1 `pubspec.yaml`

- [x] Fix description typo (leading space), add `repository: https://github.com/binkapS/binkap_parsely`, `issue_tracker: …/issues`, `topics: [text, parsing, rich_text, mentions, hashtags, links]`, `screenshots:` (once §10 renders exist), `authors:` or rely on repo admins, bump SDK floor (see §2.2 table), bump `flutter_lints` to current.
- [x] Decide on zero-dependency posture and state it in README (“0 dependencies — core”).

### 11.2 README (current 149 lines — restructure)

- [x] Add badges: pub.dev version, pub points, likes, license, CI status.
- [x] Table of contents; “Getting started” (pubspec + one minimal snippet), “Full example” (matching the example app, *not* the current README snippet which uses `ParselyOptions(parseMentionTag…)` old names and no `textScaler`).
- [x] Screenshots/GIF per feature (parse, mask, humanize, selectable).
- [x] **API reference section** replacing the empty “Dictionary” header (line 103): auto-linked dartdoc + hand-written tables for `Parsely`, `ParselyOptions`, `ParselyMask`, `ParselyElement`, `ParselyType` (document `start/end`, `displayText` if added).
- [x] Usage matrix: “I want to…” recipes (mask phones like `• • • 1234`; make only links tappable; launch links; extract entities without a widget).
- [x] Troubleshooting/FAQ: “Why isn't my email detected?” (until §3.1 fix ships — then remove), “Offsets vs grapheme clusters”, regex limitations, RTL note.
- [x] “Privacy & masking” section (§11.3).

### 11.3 Privacy note (important, currently undocumented)

**Masking is display-only.** The original value is still in memory and still delivered to `onTap`. Anyone who assumes “masked = redacted on device” will leak PII. README + dartdoc must state this explicitly, and the new API should make the *display* vs *payload* distinction impossible to confuse (the `displayText` field in §5.3).

### 11.4 Other docs

- [x] `CHANGELOG.md`: adopt “Keep a Changelog” format with `## [Unreleased]` on top, `## [0.1.0] - date` entries; document any breaking change under `Removed/Changed`.
- [x] `CONTRIBUTING.md`: it ends mid-flow (fork + clone). Add: setup (`flutter pub get`), checks (`flutter analyze && flutter test`), PR conventions, issue template expectations, code of conduct (link to a CoC), how to add a new entity type end-to-end (enum → regex → tests → docs → example).
- [x] `LICENSE`: add year + holder name (`Copyright (c) 2026 Binkap S` — currently just “Binkap S”); keep MIT.
- [x] `analysis_options.yaml`: turn on `public_member_api_docs` and a couple of `flutter_lints` rules; exclude `example/` from strict rules if needed.

---

## 12. Packaging, CI/CD & community

- [x] **P1 — GitHub Actions `flutter_test.yml`:** `flutter pub get && flutter analyze && flutter test --coverage` on push/PR; cache pub; fail on `dart format` drift. This alone unlocks pub.dev’s CI badge and the “tested” points.
- [x] **P1 — `dart pub publish --dry-run`** in CI before tag (catches missing `repository`/screenshots early).
- [ ] **P2 — Dependabot** (pub + actions), **P2 — issue/PR templates** (`.github/ISSUE_TEMPLATE/…`, `PULL_REQUEST_TEMPLATE.md`), **P2 — Code of Conduct**.
- [x] **P2 — `melos` or workspace? No.** Single package + `example/` path-dep is the right shape; do not add a monorepo tool.
- [x] **P2 — Versioning discipline:** SemVer for pub packages: `0.x` allows breaking in minor, `1.0` does not. The §14 plan respects that. Add a `RELEASING.md` checklist (bump version → CHANGELOG → publish → tag → GitHub release).
- [x] **P2 — `pub.dev` scoring pass:** after P0–P1 land, run the pub.dev checklist manually (archive contains README+LICENSE+CHANGELOG; example runs; no `pubspec.lock` committed; `homepage` not a dead link).

---

## 13. Architecture refactoring

### 13.1 Guiding split: pure-Dart core, Flutter wrapper

The parser currently imports `flutter/gestures` + `flutter/material`, so it cannot run in a Dart-only context (isolates, server, CLI). The refactor is mechanical:

```text
lib/
├── binkap_parsely.dart        # barrel: widget + core re-exports
├── parser.dart                # NEW — exports pure-Dart core (no Flutter import)
├── src/
│   ├── types.dart             # ParselyType enum (+ maybe custom entity extension)
│   ├── entity.dart            # ParselyElement (with value equality, offsets, displayText)
│   ├── options.dart           # ParselyOptions (const, copyWith, ==, enabledEntities)
│   ├── masks.dart             # ParselyMasks (Map-based) + deprecated ParselyMask shim
│   ├── engine.dart            # EntityEngine: regex set + overlap resolution (pure Dart)
│   ├── regexes.dart           # all RegExp as static finals, documented
│   ├── humanize.dart          # display transforms (pure functions)
│   └── app/shell              # (tree adjusted; see Appendix B)
```

Rules: `src/engine.dart`, `regexes.dart`, `humanize.dart`, `options.dart`, `masks.dart`, `entity.dart`, `types.dart` import **zero** `package:flutter/…`. The widget (`parsely.dart`) consumes them. Tests for the core then need no widget bindings and run under `dart test` as well as `flutter test`.

### 13.2 Renames (breaking, group in one release)

| Today | Proposed | Reason |
|---|---|---|
| `ParselyMask(matches, masks)` | `ParselyMasks(exact, patterns, maskAll)` + `maskBuilder` fn | parallel lists are fragile (§3.5) |
| `parseHashTag` / `parseMentionTag` | `parseHashtag` / `parseMention` | capitalization consistency |
| `humanize` | `stripLinkScheme`, `stripMentionPrefix` (or `displayBuilder`) | one flag doing two unrelated transforms |
| `Parser.parse` (String field) | `Parser.text` / engine input param | `parse` reads as a verb; clashes with method names |
| `ParselyUtil` singleton | top-level functions / static helpers | singleton adds no value |
| `ParselyData` (internal) | `_RawMatch` private | it is internal plumbing leaking into `src/` |
| `binkap_parsely.dart` barrel | keep name (package name), add `parser.dart` export target | — |

### 13.3 Extensibility: custom entity types (P2)

Define a pluggable `EntityRule { ParselyType type (or String id), RegExp regex, int priority }`. A future `customRules: List<EntityRule>` lets consumers add currency/IDs/order-numbers without waiting for a release. This is the correct answer to “what about CVEs / order IDs / IP addresses?” — ship the escape hatch, not every regex.

---

## 14. Feature roadmap by release

### Milestone 1 — `0.1.0` “Stabilize” (S/M effort, **do first**)
*Bugs + smallest possible surface to be correct & testable. No breaking changes except additive.*

- [x] §3.1 email regex fix, §3.2 span-offset fix + overlap skip, §3.4 humanize regex, §3.3 Stateful + recognizer dispose, §3.6 idempotent parser + `static final` regexes
- [x] `onTap` becomes optional (additive), `textScaler` default → ambient (fix a11y regression), default `parsedStyle` from theme
- [x] Offsets + `displayText` on `ParselyElement`; `==`/`hashCode`/`toString`/`copyWith` on models
- [x] Headless `extract()` API (§8)
- [x] Full unit test suite for parser (§9.1) + widget regression tests for §3.2 vectors
- [x] Runnable example (§10 P0 items), dartdoc on all public API, README restructure + privacy note, pubspec fixes (description/repository/topics/SDK floor/lints bump), CHANGELOG under Keep-a-Changelog, CONTRIBUTING completed, LICENSE year
- [x] CI (§12 P1) green; `flutter pub publish --dry-run` passes

### Milestone 2 — `0.2.0` “Polish” (breaking-change window — group all renames here)

- [x] §4 regex upgrades (long TLDs, phone separators/extensions, unicode hashtag/mention, boundaries, trimming, overlap priority table) behind the *existing* 5 bools first; ship the corpus tests from Appendix A
- [x] §5.4 `ParselyMasks` + `maskBuilder` (old `ParselyMask` deprecated shim); §5.2 renames (`parseHashtag`/`parseMention`, `stripLinkScheme`/`stripMentionPrefix`) with deprecated aliases removed *in the same release notes*
- [x] Per-type styles/handlers, `enabledEntities` set, memoized parsing, semantics labels, selectable variant (§5.1 P1/P2)
- [x] Launch helpers (zero-dep default: build `Uri`, let consumer launch; optional `url_launcher` entrypoint)
- [x] Example kitchen-sink + screenshots/GIFs + pub.dev scoring pass

### Milestone 3 — `0.3.0` “Extensible”

- [x] Custom `EntityRule` (§13.3); currency/IP/date as *example rules* (not built-in types until real usage demands it)
- [x] `partialMask` helper + mask-by-type presets (chat-app “****1234”)
- [x] Validation hooks (§4.5); progressive/async parsing for large texts; performance benchmark published
- [x] Golden test suite (§9.2) + RTL/unicode vectors

### Milestone 4 — `1.0.0` “Stable”
- [x] Freeze API; remove deprecated shims; full migration guide; long-lived support promise in README

### Explicitly out of scope (say so in README)
- Text *editing* (input fields with live entity highlighting) — that is a different widget (`ParselyTextField`); the engine (§13) will make it easy later, but it is not this package's scope yet.
- Markdown rendering — compose with `flutter_markdown`, don't reimplement.
- Server EXIF/metadata stripping — unrelated.

---

## 15. Migration guide (planned breaking changes)

*Publish this section in README at the `0.2.0` bump; ship `0.1.0` without breaking anything.*

| Before (deprecated) | After | Migration |
|---|---|---|
| `ParselyMask(matches: ['+234…'], masks: ['My Contact'])` | `ParselyMasks(exact: {'+234…': 'My Contact'})` or `maskBuilder: (e) => …` | 1:1 map; length-mismatch assert gone |
| `ParselyOptions(parseHashTag: false)` | `ParselyOptions(parseHashtag: false)` | rename; old name removed after 1 minor |
| `ParselyOptions(parseMentionTag: false)` | `ParselyOptions(parseMention: false)` | rename |
| `ParselyOptions(humanize: true)` | `ParselyOptions(stripLinkScheme: true, stripMentionPrefix: false)` | default changes (mention `@` now kept — see §17 decision) |
| `required onTap` | `ValueChanged<ParselyElement>? onTap` | optional; no code change needed for existing callers |
| `textScaler: TextScaler.noScaling` (default) | ambient scaler (default) | if you relied on no scaling, pass `TextScaler.noScaling` explicitly |
| `parsedStyle: Colors.blue` (default) | theme-derived | pass `parsedStyle` explicitly if you want blue |

---

## 16. Prioritized backlog (master table)

| # | Item | Milestone | Effort | Impact | Risk | File(s) |
|---|---|---|---|---|---|---|
| 3.1 | Email regex anchor fix | 1 | S | Critical (broken feature) | Low | `parser.dart` |
| 3.2 | Span offset + overlap corruption | 1 | S/M | Critical (wrong render) | Low | `parser.dart` |
| 3.3 | Stateful + recognizer dispose | 1 | S | Critical (leak) | Med | `parsely.dart`, `parser.dart` |
| 3.4 | Humanize regex fix | 1 | S | High | Low | `util.dart` |
| 3.5 | Mask API | 2 | M | High | **High (breaking)** | `mask.dart` |
| §7 | `textScaler` a11y default | 1 | S | High | Med | `parsely.dart` |
| §6 | Memoization | 2 | M | Med | Low | `parsely.dart` |
| §8 | Headless `extract()` | 1 | S | High | Low | new `parser.dart` |
| §9 | Unit/widget tests | 1 | M | Critical (safety net) | Low | `test/` |
| §10 | Example `pubspec.yaml` + runnability | 1 | S | High | Low | `example/` |
| §11 | README/pubspec/docs | 1 | M | High (pub.dev) | Low | config/docs |
| §12 | CI | 1 | S | High (publishing) | Low | `.github/` |
| §4 | Regex upgrades | 2 | M | High | Med | `parser.dart` |
| §5.1 | Per-type style/handlers | 2 | M | Med | Med | `parsely.dart`, `option.dart` |
| §5.1 | `SelectableParsely` | 2 | M | High (chat apps) | Med | new file |
| §5.1 | Built-in launch | 2 | S/M | High | Med | new file(s) |
| §13.3 | Custom `EntityRule` | 3 | M | High (future) | Med | engine |
| §7 | Unicode/RTL + semantics | 2/3 | M | Med | Low | regexes/tests |

---

## 17. Open questions / decisions needed

> Resolve these *before* Milestone 2 so the breaking window is clean. Each is marked with a default recommendation — override if you disagree and note it in the CHANGELOG.

- [x] **[~] `humanize` default for mentions:** today `humanize=true` strips `@`. Recommended: default to *keeping* `@` (strip only link scheme). Does any existing consumer depend on the stripped form?
- [x] **[~] Overlap priority order:** proposed `email > link > phone > hashtag > mention`. Any use case where a hashtag inside a URL should win over the link?
- [x] **[~] Masked-value copy semantics:** should copying a masked span copy the *display* text or the *original*? Recommended: **display** (privacy-preserving), documented. Override?
- [x] **[~] `url_launcher` as an optional entrypoint** vs. zero-dep core + glue snippet. Recommended: zero-dep core, `binkap_parsely_launch.dart` optional entrypoint. OK?
- [x] **[~] Phone validation depth:** regex-only + hook (recommended) vs. hard dependency on `google_phone_number_validation`. Confirm cost/benefit.
- [x] **[~] Package rename?** `binkap_parsely` is discoverable but wordy; renaming on pub.dev post-0.1.0 is disruptive. Recommendation: **keep the name**, invest in `topics`/`description` instead. Revisit at 1.0.0?

---

## 18. Definition of done

- [x] `flutter analyze` clean; `flutter test` ≥ 80% coverage on parser; `dart format --set-exit-if-changed` passes; CI green on `main`.
- [x] `cd example && flutter run` works on at least one platform from a clean checkout.
- [x] `dart pub publish --dry-run` passes; pub.dev checklist (§11/§12) reviewed.
- [x] README example compiles verbatim (copy-paste test); screenshots match the example app.
- [x] Every P0 in §3 has a regression test named `regression_<issue>_<slug>`; every breaking change in §15 has a migration note.
- [x] CHANGELOG has an `Unreleased` section that matches what ships.

---

## Appendix A — regex reference & test corpus

Keep this table in the repo as `test/regex_notes.md` (or dartdoc on `regexes.dart`) so a future contributor can extend a pattern without re-deriving it:

| Entity | Must match | Must NOT match | Notes |
|---|---|---|---|
| Email | `a@b.co`, `first.last+tag@sub.domain.example`, `A@B.COM` | `a@`, `@b.com`, `a@@b.com`, `a b@c.com`, `a@b..com` | trim trailing `.,;:!?`; reject if `Uri.parse` domain invalid |
| Link | `https://example.com`, `www.example.com/path?q=1#f`, `example.technology`, `xn--nxasmq6b.example`, `example.com:8080/` | `http://`, `www.`, `foo@bar.com` (email wins), `example.c` (1-char TLD) | TLD `≥2` or punycode; balanced-paren trailing trim |
| Phone | `+234 806 898 9116`, `(0803) 123-4567`, `0803/1234567`, `+1 (555) 123-4567 ext. 42` | `123456` (too short), `2024-01-15` (date), bare 16-digit card | digit-count 7–15 (E.164); don't match inside longer digit runs |
| Hashtag | `#flutter`, `#🎉`, `#مرحبا`, `#_private` | `#123`, `#1`, `a#b`, `#` alone | ≥1 non-digit char; unicode; preceding boundary |
| Mention | `@dartlang`, `@binkap` | `@123`, `a@b.com` tail, `@@user` | same as hashtag; email-tail guard |

Fuzz/benchmark entrypoint: feed 100 KB of mixed sample text through `extract()` and assert < 100 ms and zero exceptions.

---

## Appendix B — target file tree & API sketch

```text
lib/
├── binkap_parsely.dart        # widget + core barrel
├── parser.dart                 # exports pure-Dart core only
└── src/
    ├── parsely.dart            # StatefulWidget + SelectableParsely
    ├── selectable_parsely.dart
    ├── entity.dart
    ├── types.dart
    ├── options.dart
    ├── masks.dart
    ├── engine.dart             # visibleForTesting
    ├── regexes.dart
    ├── humanize.dart
    └── launch.dart             # (optional entrypoint glue)
test/
├── parser_test.dart            # §9.1 corpus
├── parsely_test.dart           # §9.2 widget + regression
├── goldens/
└── benchmark_test.dart
example/                        # runnable app (§10)
```

Core API sketch (post-0.2.0, additive-compatible first):

```dart
// pure Dart (no flutter imports)
List<ParselyElement> ParselyParser.extract(
  String text, {
  ParselyOptions options = const ParselyOptions(),
  String? Function(ParselyElement)? maskBuilder,
  List<EntityRule> customRules = const [],
});

// widget
Parsely(
  text: '…',
  style: …, parsedStyle: …,
  parsedStyles: {ParselyType.link: …},        // per-type (optional)
  options: ParselyOptions(parseHashtag: false, stripLinkScheme: true),
  maskBuilder: (e) => e.type == ParselyType.phone ? '••• ${e.parsed.suffix(4)}' : null,
  enabledEntities: {ParselyType.link, ParselyType.email},
  onTap: (e) { /* e.parsed (original), e.displayText, e.start/end */ },
  onLinkTap: (e) { launch(e.uri); },           // per-type convenience
)
```

The engine guarantees: non-overlapping spans, deterministic priority (§4.3), stable offsets, and display-vs-payload separation everywhere.

---

*End of plan. Execute Milestone 1 first — it fixes corrupt rendering, a leak, and the non-runnable example, and gives you a test suite that guards every later milestone.*
