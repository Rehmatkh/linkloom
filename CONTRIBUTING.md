# Contributing to net_pulse

Thanks for helping improve net_pulse! 

## Reporting a bug / fixing an issue

1. Search [existing issues](../../issues) first — someone may have already
   hit it.
2. Open a new issue using the **Bug report** template. Include:
   - Flutter/Dart version (`flutter --version`)
   - Minimal reproduction steps or code snippet
   - Expected vs actual behavior
3. If you can fix it yourself:
   - Fork the repo, create a branch: `git checkout -b fix/short-description`
   - Add/update a test in `test/` that covers the bug
   - Run `flutter test` and `flutter analyze` — both must pass
   - Open a PR against `main`, link the issue with `Fixes #<number>`

## Adding a feature

1. Open an issue first with the **Feature request** template to discuss
   scope before writing code — avoids wasted effort.
2. Keep the package's two core responsibilities in mind (offline queue +
   connectivity UI) — if a feature doesn't fit either, it may belong in a
   separate package.
3. Update `README.md` and `CHANGELOG.md` alongside code changes.

## Local setup

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/net_pulse.git
cd net_pulse
flutter pub get
flutter test
cd example && flutter pub get && flutter run
```

## Release checklist (maintainers)

1. Bump `version:` in `pubspec.yaml` (semantic versioning).
2. Add an entry to `CHANGELOG.md`.
3. `flutter analyze` and `flutter test` must be clean.
4. `flutter pub publish --dry-run` to sanity check.
5. Tag the release: `git tag vX.Y.Z && git push --tags`
6. `flutter pub publish`
