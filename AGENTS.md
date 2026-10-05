# MRE Quran engineering guide

## Toolchain

- Use `fvm flutter`; this repository pins Flutter 3.47.5 and Dart 3.13.4.
- Run `fvm flutter pub get` after a dependency change.
- Run `dart format --output=none --set-exit-if-changed lib test`.
- Run `fvm flutter analyze` and `fvm flutter test` before committing.
- Use `fvm flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` for Android release candidates.

## Architecture

- Keep `lib/core` for cross-cutting code only.
- Put feature code in `data`, `domain`, `application`, and `presentation` layers.
- Domain code has no Flutter imports.
- State belongs in Riverpod providers. Widgets only render state and send intents.
- Route through typed `go_router` routes. Do not add direct navigation stacks for app flows.
- Keep public APIs documented, types explicit, and files focused.

## Quran content

- Never hand-edit Quran text, page map, glyph sequence, or ayah metadata.
- Only commit checked, immutable source files with a documented provenance and SHA-256.
- Keep derived search keys separate from verbatim Quran text.
- Do not add images, page scans, fonts, audio, tafsir, or translations without recording source, licence, checksum, and attribution.

## Product and privacy

- Arabic is the default locale; every user-facing string belongs in ARB files.
- Support compact, medium, and expanded widths. Branch on constraints, never device names.
- Respect `MediaQuery.disableAnimations`; do not use blur over reader content.
- No analytics. Crash reporting must be opt-in and cannot initialise until a Firebase project is configured.
- Do not request permissions at launch.

## Tests

- Add unit tests for domain/application logic.
- Add widget tests for Arabic RTL, English, dark mode, large text, compact, medium, and expanded layouts.
- Use integration tests for persisted reading state after the reader data source is approved.
