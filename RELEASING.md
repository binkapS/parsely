# Releasing Parsely

> Keep the [CHANGELOG.md](CHANGELOG.md) under the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format and follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This checklist is the single source of truth for a pub.dev release. Do not publish from a branch; releases are cut from `main` only.

## 1. Bump

1. Update `version` in [pubspec.yaml](pubspec.yaml) to the next SemVer version.

   ```yaml
   version: 0.1.0   # example
   ```

   SemVer rules for pub packages:

   - `0.x` may include breaking changes in minor bumps.
   - `1.0` and later must not include breaking changes in minor bumps; breaking changes require a major bump.
   - Group all breaking renames/API changes into a single release and note them in the migration guide in [README.md](README.md).

2. Ensure `description`, `homepage`, `repository`, `issue_tracker`, and `topics` in `pubspec.yaml` still point at the live repository and describe the package accurately.

## 2. CHANGELOG

1. Move the entries under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) into a new `## [X.Y.Z] - YYYY-MM-DD` section.
2. Document every user-visible change under `Added` / `Changed` / `Removed` / `Fixed` / `Security`.
3. Document every breaking API change under `Removed` or `Changed`, with a migration note (old name → new name, e.g. `parseHashTag` → `parseHashtag`).
4. Leave a fresh, empty `## [Unreleased]` section at the top for the next cycle.
5. If the release introduces a new public API surface, update the API reference tables and "I want to…" recipes in [README.md](README.md) in the same change.

## 3. Verify (locally and in CI)

Run all of these from a clean checkout and confirm they pass before tagging:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test --coverage
dart pub publish --dry-run
```

- CI (`.github/workflows/flutter_test.yml`) runs the same commands on every push/PR to `main` — confirm the `flutter_test` workflow is green on the release commit.
- Confirm `cd example && flutter run` works on at least one platform from a clean checkout.
- Confirm `dart pub publish --dry-run` passes (catches missing `repository`/screenshots/other publish blockers).

## 4. Publish to pub.dev

```bash
git push origin main
dart pub publish
```

1. Confirm the version published on pub.dev matches the `version` in `pubspec.yaml`.
2. Do not commit `pubspec.lock`.
3. Do not publish any pre-release (`0.0.x` / `pre`) versions to pub.dev without intentional versioning.

## 5. Tag

After pub.dev confirms a successful publish, tag the exact commit that was published:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

The tag name is `v` followed by the SemVer version (e.g. `v0.1.0` for version `0.1.0`). Do not move or retag a release tag; create a new release instead.

A GitHub Release will be created from this tag pointing at the pub.dev listing. No additional steps are required for the tag push to register the release.

## 6. GitHub Release

1. Open the tag `vX.Y.Z` in GitHub Releases.
2. Copy the versioned section from [CHANGELOG.md](CHANGELOG.md) into the release notes.
3. Add a line linking to the pub.dev listing for `binkap_parsely` at version `X.Y.Z`.
4. Include any breaking-change migration notes referenced from the CHANGELOG/README.
5. Publish the release as the latest release for `vX.Y.Z`.

## 7. Post-release checks

- [ ] `pubspec.yaml` `version` on `main` is ready to bump to the next development version (optional: open a follow-up or coordinate).
- [ ] pub.dev, README badges, GitHub Release notes, and CHANGELOG all agree on the version.
- [ ] CI badge on README points at the real workflow (`.github/workflows/flutter_test.yml`) and is green.
- [ ] If the release included screenshots/GIFs or `pubspec.yaml` `screenshots`, confirm they render on pub.dev.

## Related

- [CONTRIBUTING.md](CONTRIBUTING.md) — local checks, PR conventions, code of conduct
- [CHANGELOG.md](CHANGELOG.md) — release notes source
- `.github/workflows/flutter_test.yml` — CI gate (format, analyze, tests with coverage, publish dry-run)
