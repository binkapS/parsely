# Contributing to Parsely

Thank you for considering contributing to Parsely! Whether you're fixing a bug, suggesting an improvement, or adding a new feature, your contributions are greatly appreciated.

## How to Contribute

1. **Fork the repository**: Click the "Fork" button at the top of the repository to create a personal copy of the project.

2. **Clone your fork**: Clone your forked repository to your local machine.

   ```bash
   git clone https://github.com/binkapS/binkap_parsely.git
   ```

3. **Install dependencies**:

   ```bash
   flutter pub get
   ```

4. **Create a branch**: Name it descriptively, e.g. `fix/link-trailing-dot` or `feat/parse-order-ids`.

   ```bash
   git checkout -b feat/your-feature
   ```

5. **Make your change**: Keep it small and focused. Parsely is zero-dependency — please do not add runtime dependencies.

6. **Run the checks** (must pass before you push):

   ```bash
   flutter analyze
   flutter test
   ```

   `dart analyze` must be clean; public members need `///` dartdoc (`public_member_api_docs`).

7. **Push and open a pull request**: Target `main`, fill in the PR template, and link any issue (e.g. `Fixes #123`).

## Setup

- Toolchain: Flutter `>=3.22.0` / Dart `>=3.3.1`.
- Run `flutter pub get` after cloning or after changing `pubspec.yaml`.
- The `example/` app is a kitchen-sink demo: `cd example && flutter run`.

## Checks

```bash
flutter pub get
flutter analyze
flutter test
```

Treat analyzer warnings as errors — the repo enforces `public_member_api_docs` and `prefer_final_locals`.

## PR conventions

- **One concern per PR**: don't mix unrelated fixes with features.
- **Small diffs**: reviewers prefer focused changes; extract pure-Dart logic into the engine (`lib/src/engine.dart`) where possible so it stays testable without Flutter.
- **Add tests**: every behavior change needs a regression test; new entity kinds need boundary tests (start/end offsets, overlap precedence, trailing punctuation).
- **Update docs**: new public API needs dartdoc plus a README entry (API table / recipe) and a `CHANGELOG.md` line under `[Unreleased]`.
- **Commit messages**: Conventional Commits style, e.g. `feat: add order-id rule`, `fix: trim trailing dot from links`, `docs: clarify masking privacy`.
- **Do not edit `lib/` docs with wide reformats** — keep changes surgical.

## Issue expectations

When filing an issue, please include:

- **What you expected** and **what happened** (two short paragraphs).
- **Minimal repro**: a short Dart snippet (text + options) or a standalone repo.
- **Environment**: `flutter --version` output and Parsely version from `pubspec.yaml`.
- Screenshots / stack traces when relevant.

Maintainers may close issues without this information — a minimal repro speeds up fixes dramatically.

## Code of conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html). By participating you agree to abide by its terms. Report violations to the maintainers via the repository's issue tracker.

## How to add a new entity type end-to-end

1. **Enum** — add a value to `ParselyType` in `lib/src/type.dart` (e.g. `orderId`) with a dartdoc comment.
2. **Regex** — add the pattern to `ParselyRegexes` in `lib/src/regexes.dart` (compiled once as `static final`), register its priority in `priorityOf`, and document boundary rules.
3. **Options** — add a `parseXxx` flag to `ParselyOptions` in `lib/src/option.dart`, wire it into `isEnabled`, `copyWith`, `==`, `hashCode`, and `toString`.
4. **Engine** — wire the regex into `EntityEngine.extract` in `lib/src/engine.dart` with its priority; add validation in `_validate` (minimum length, boundary checks, false-positive guards) and trailing-punctuation handling if needed.
5. **Widget** — ensure `Parsely` and `SelectableParsely` pick up the new type automatically (per-type style via `parsedStyles`, handler via `onTapHandlers`); add a semantic label in both widgets.
6. **Launch** — if the entity is launchable, extend `ParselyElement.uri` in `lib/src/element.dart` (otherwise return `null`); update `ParselyLaunch` docs if the scheme is new.
7. **Tests** — add extraction tests (match + offsets + precedence + false positives) and a widget test (tap delivers the original `parsed`).
8. **Docs** — add the new type to the README API tables and a recipe, plus a `CHANGELOG.md` `[Unreleased]` entry.
9. **Checks** — `flutter analyze && flutter test` must pass.

## License

By contributing you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
