---
name: Bug report
about: Report a parsing, rendering, or widget bug in Parsely
title: "[Bug]: "
labels: bug
assignees: ''
---

## Description

A clear and concise description of what the bug is.

- **Expected behaviour:**
- **Actual behaviour:**

## Minimal reproduction

> Fill in all parts you can. A minimal snippet greatly speeds up fixes.

**Input text:**

```dart
// Paste the exact string passed to Parsely / ParselyParser.extract
// e.g. Parsely(text: 'Mail me at a@b.com or call +2348068989116 #flutter')
```

**Code:**

```dart
import 'package:binkap_parsely/binkap_parsely.dart';

// Parsely(...)
// options: const ParselyOptions(...)
// masks / maskBuilder / enabledEntities / customRules, if any
```

**Relevant output** (if any — spans, `extract()` result, widget output):

```text
// Paste ParselyParser.extract(...) output or stack traces here
```

## Parsely / Flutter versions

- Parsely version (`pubspec.yaml`): e.g. `binkap_parsely: ^0.1.0`
- Flutter version: paste `flutter --version` output
- Dart version (if relevant): paste `dart --version` output

## Platform

- [ ] Android
- [ ] iOS
- [ ] Web
- [ ] macOS
- [ ] Windows
- [ ] Linux
- [ ] Other:

## Additional context

- Entity types involved (link / email / phone / hashtag / mention / custom rule):
- Whether offsets (`start` / `end`) or `onTap` payload (`parsed` vs `displayText`) are wrong:
- Screenshots / screen recordings / widget inspector output, if relevant:
