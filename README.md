# MRE Quran

Arabic-first Flutter foundation for a Quran app. Android and iOS runners are included.

## Run

Use Flutter 3.47.5 / Dart 3.13.4, pinned in `.fvmrc`. With FVM, run
`fvm install` and prefix Flutter commands with `fvm`.

```sh
flutter pub get
flutter run
```

## Structure

- `lib/app`: application composition, Arabic localization, shared navigation.
- `lib/core`: themes, width breakpoints, constrained content and shared empty states.
- `lib/features/<feature>/presentation`: views and controllers.
- `lib/features/settings/data`: repository contract and local preference storage.
- `lib/main.dart`: dependency composition and initial settings loading.

Dependencies are passed through constructors. Controllers own application state;
views own layout and navigation selection. Add data repositories to features when
real data sources exist. Keep Quran data access out of widgets.

## Current behavior

- Arabic locale and RTL, with Flutter's localized Material controls.
- System, light and dark themes, saved locally with `SharedPreferencesAsync`.
- Storage errors are visible in Settings and can be retried.
- Bottom navigation below 600 logical pixels, labeled rail from 600 to 839,
  extended rail from 840. Content is capped at 960 logical pixels.
- Navigation selection survives resizing; tab widgets remain mounted.
- Mushaf and bookmarks currently show explicit empty states.

## Quran data boundary

No Quran text, surah catalogue, audio or bookmark persistence is bundled yet.
Before implementing reading, select and document a licensed, verified text source,
its edition/riwayah, verse numbering and checksum. Keep the original text intact;
search normalization must operate on a separate derived value. Validate the full
corpus before shipping. Choose a licensed Quran font matching that source.

## mre_fields decision

Reviewed https://pub.dev/packages/mre_fields and the adjacent package README.
The package provides automatic text direction, text/form fields, phone input and
image paste. It fits future surah search and personal notes. This foundation has
no free-text fields, so it does not add the dependency yet. When adding search,
verify the published version and wrap only the app-specific field configuration.
It is not a Quran rendering or Quran data package.

## Validation

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Widget coverage checks Arabic RTL, navigation, theme interaction, resizing,
320/600/839/840/1200 widths and enlarged text. Controller tests cover saved state,
read/write failures and retry. No backend exists; API and audio tests do not apply.
Device rendering and a release build still need validation before distribution.
