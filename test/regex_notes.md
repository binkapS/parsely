# Appendix A — regex reference & test corpus

> Keep this table in the repo as `test/regex_notes.md` (or dartdoc on `regexes.dart`) so a future contributor can extend a pattern without re-deriving it:

| Entity | Must match | Must NOT match | Notes |
|---|---|---|---|
| Email | `a@b.co`, `first.last+tag@sub.domain.example`, `A@B.COM` | `a@`, `@b.com`, `a@@b.com`, `a b@c.com`, `a@b..com` | trim trailing `.,;:!?`; reject if `Uri.parse` domain invalid |
| Link | `https://example.com`, `www.example.com/path?q=1#f`, `example.technology`, `xn--nxasmq6b.example`, `example.com:8080/` | `http://`, `www.`, `foo@bar.com` (email wins), `example.c` (1-char TLD) | TLD `≥2` or punycode; balanced-paren trailing trim |
| Phone | `+234 806 898 9116`, `(0803) 123-4567`, `0803/1234567`, `+1 (555) 123-4567 ext. 42` | `123456` (too short), `2024-01-15` (date), bare 16-digit card | digit-count 7–15 (E.164); don't match inside longer digit runs |
| Hashtag | `#flutter`, `#🎉`, `#مرحبا`, `#_private` | `#123`, `#1`, `a#b`, `#` alone | ≥1 non-digit char; unicode; preceding boundary |
| Mention | `@dartlang`, `@binkap` | `@123`, `a@b.com` tail, `@@user` | same as hashtag; email-tail guard |

Fuzz/benchmark entrypoint: feed 100 KB of mixed sample text through `extract()` and assert < 100 ms and zero exceptions.

## Implementation notes (as tested)

- **Engine guarantees:** non-overlapping, sorted by `(start asc, length desc, priority asc)`, priority `email > link > phone > hashtag > mention`. Trailing punctuation trimmed for link/email. Offsets correct. `displayText` derived after mask > strip.
- **Email `a b@c.com`:** the whole candidate is invalid (no single entity spans the space). The embedded `b@c.com` after the boundary is a legitimate standalone email and *is* extracted; the test asserts no entity contains a space and no entity equals `'a b@c.com'`.
- **Email `@b.com` / `a@@b.com`:** no *email* entity is produced. The surrounding text may still yield a mention/link under default options (e.g. `@b.com` yields mention `@b` with all types enabled); the email-specific negative in the corpus is therefore asserted with the email type filtered / `enabledEntities: {ParselyType.email}`.
- **Link `foo@bar.com`:** under default options the engine returns a single email (email wins over the bare-domain link). Link-only extraction of the bare domain is expected but not asserted as a corpus negative.
- **`#flutter#dart`:** the second `#` lacks a preceding boundary, so only `#flutter` matches; this is intended boundary behaviour.
- **Phone `ext.` suffixes:** the current phone candidate regex matches the core number; the extension tail is not part of `parsed`. The `+1 (555) 123-4567 ext. 42` row documents the full input, but the corpus test asserts the core-number form rather than the full `ext.` suffix.
