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

## UI/UX quality bar

- Build every screen to feel polished and intentional. Pick the best UX, not the quickest.
- Never rebuild or reload a whole page for a small change. Scope rebuilds:
  - Use `ref.watch(provider.select(...))` and split widgets so only the part that changed rebuilds.
  - Use `const` constructors, stable keys, and `RepaintBoundary` around heavy or animated parts.
  - Keep scroll position, selection, and focus across state changes and locale/theme switches.
- Never show a full-screen spinner that replaces existing content.
  - On refresh or background update, keep the current data visible and update it in place.
  - Use `AsyncValue` with `skipLoadingOnRefresh`/`skipLoadingOnReload` (or the equivalent) so stale data stays on screen.
- Use shimmer skeletons for the first load of any async content.
  - Use one shared shimmer in `lib/core/widgets`. Do not add a per-feature copy.
  - Make skeletons match the final layout (same size, spacing, and corner radius) so nothing jumps when data arrives.
  - Shimmer must respect `MediaQuery.disableAnimations` and fall back to a static placeholder.
  - Shimmer must work in light and dark themes and in RTL, using directional gradients.
  - Use shimmer only for loading. Never use it to hide errors or empty states.
- Build reusable widgets once in `lib/core/widgets` and reuse them everywhere.
  - Before writing a widget, check `lib/core/widgets` for an existing one. Extend it instead of copying.
  - If a pattern appears in a second place, extract it to a shared widget.
  - Use `AppSelectField` for every single-choice picker. Never use `DropdownButton`,
    `DropdownButtonFormField`, or `DropdownMenu` directly.
  - A picker with more than 5 options must show a search field.
- Every async screen handles four states explicitly: loading (shimmer), data, empty, and error with a retry action. Strings come from ARB files.
- Prefer optimistic updates for small user actions (bookmark, favourite, setting toggle). Roll back with a clear message on failure.
- Do not show a loading indicator for work shorter than about 150 ms. Avoid flicker.
- Animate transitions (`AnimatedSwitcher`, `AnimatedSize`, hero) with short, purposeful durations that respect `disableAnimations`.
- Keep touch targets at least 48dp, give visible pressed and focus states, and meet contrast in both themes.
- Never block the UI thread. Move heavy parsing or search work off the main isolate.
- Before finishing UI work, check it on a compact and an expanded width, in dark mode, with large text, and in Arabic RTL.

## Design system

- Use the `mre-quran-design-system` skill for any UI work.
- Take colours only from the `ColorScheme`. Never hard-code colours in feature code.
- Take radius, spacing, and sizes from `AppTokens`. Add a token instead of repeating a number.
- Use the Material 3 filled field style defined once in `AppTheme`. Do not restyle a field per screen.
- Use `MRETextField`/`MRETextFormField` (`mre_fields`) for every text input and keep `MREFieldsTheme` wired to `AppTokens`.
- Make every platform feel native. Read the platform from `Theme.of(context).platform` (via `context.isCupertino`), never from `defaultTargetPlatform`, so Device Preview and tests can switch it.
  - iOS/macOS: liquid glass (`liquid_glass_widgets`) for app chrome: app bar, tab bar, rail, sheets, and cards. Keep it readable in light, dark, and sepia.
  - Android and other platforms: stock Material 3 (`AppBar`, `NavigationBar`, `NavigationRail`, `Card`, `showModalBottomSheet`). No glass.
  - Put platform branching in shared widgets (`AppShell`, `AppCard`, `AppSelectField`), not in feature screens.
- Pad content with `pagePadding(context)` and never place glass over Quran text.
- Use `AppCard` for grouped content. Do not use bare `Card`, `GlassCard`, or `showModalBottomSheet` in app screens.
- Pick the bottom tab bar on compact widths and the rail on medium and expanded widths.
- Device Preview (`device_preview_plus`) is enabled in debug builds only. Check UI by switching the simulated device between iOS and Android.

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
