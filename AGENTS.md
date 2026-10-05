# MRE Quran engineering guide

## Toolchain

- Use `fvm flutter`; this repository pins Flutter 3.47.5 and Dart 3.13.4.
- Run `fvm flutter pub get` after a dependency change.
- Run `dart format --output=none --set-exit-if-changed lib test`.
- Run `fvm flutter analyze` and `fvm flutter test` before committing.
- Measure performance with the commands in `docs/PERFORMANCE.md` after changing start-up, the shell, sheets, or the index.
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

## Housekeeping

- Delete any file you create only to extract or inspect something (scripts, dumps,
  screenshots, logs, scratch copies) as soon as you have what you need.
- Never leave unused files, dead code, or unreferenced assets in the repo.
  Remove a file when its last use is removed.
- Put throwaway files in the session scratchpad, never inside the repository.

## Product and privacy

- Arabic is the default locale; every user-facing string belongs in ARB files.
- Support compact, medium, and expanded widths. Branch on constraints, never device names.
- Respect `MediaQuery.disableAnimations`; do not use blur over reader content.
- No analytics. Crash reporting must be opt-in and cannot initialise until a Firebase project is configured.
- Do not request permissions at launch.
- Use `AppLogger` for diagnostic output and crash reporting. Do not emit PII,
  do not write errors to Firestore, and do not call `print` directly outside
  the logger or platform bootstrap.

## UI/UX

- Read `docs/UI_RULES.md` before any UI work. It is the single rule file for UI/UX, and `docs/UI_UX_PLAN.md` holds the design plan.
- Use the `mre-quran-design-system` skill for UI work.
- Never hard-code colours, radii, or spacing. Use `ColorScheme` and `AppTokens`.
- Make each platform native: liquid glass on iOS, Material 3 on Android, chosen by `context.isCupertino`.
- Reuse `lib/core/widgets` components; never restyle per screen.

## Localization and bidirectionality

- Use the `mre-quran-localization` skill for localized UI work.
- Keep UI strings in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.
- Use the generated typed `AppLocalizations` API through `context.l10n`.
- Do not add string-key translation maps or static current-locale state.
- Use only directional layout APIs: `EdgeInsetsDirectional`,
  `BorderRadiusDirectional`, `AlignmentDirectional`, `PositionedDirectional`,
  `TextAlign.start`, and `TextAlign.end`.
- Never use `left`, `right`, `EdgeInsets.fromLTRB`, physical `Alignment`, or
  `Positioned` for locale-relative layout. Exception: verified Mushaf page
  geometry may be physical only inside a dedicated renderer, documented inline
  and covered by an RTL/LTR test; it must never leak into ordinary UI.

## Tests

- Add unit tests for domain/application logic.
- Add widget tests for Arabic RTL, English, dark mode, large text, compact, medium, and expanded layouts.
- Use integration tests for persisted reading state after the reader data source is approved.
