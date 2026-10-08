# Progress

## Done

- Audited the existing project and toolchain.
- Confirmed Flutter 3.47.5 / Dart 3.13.4 is installed through FVM.
- Recorded architecture, adaptive, privacy, and Quran-data guardrails.
- Created the implementation plan and decision log.
- Audited public Golden Quran feature categories and documented a differentiated
  delivery order.
- Added a local localization/directionality skill and RTL/LTR API guard test.
- Replaced broken `liquidify` with `liquid_glass_widgets`; the restrained glass
  system now covers application chrome on iOS and Android without a native fork.
- `mre_fields` is used for the search input. Its Android transitive Kotlin
  plugin warning is recorded for dependency monitoring.
- Created the Firebase project for MRE Quran, registered Android and iOS, and
  generated FlutterFire configuration.
- Integrated Firebase Crashlytics with an explicit, persisted, default-off
  Settings control. Firebase Analytics was not added.

- Shared UI system: tokens, harmonised themes, platform-native shell, draggable `AppSheet`,
  `AppCard`, `AppSelectField`, `AppSwitchTile`, optimistic settings, Device Preview 3 with
  platform sync, launch setting (last tab / Mushaf), Duas tab placeholder.
- Wrote `docs/UI_RULES.md`, `docs/UI_UX_PLAN.md`, and `docs/QURAN_SOURCES.md`.

- Quran index: Tanzil metadata bundled with a checked SHA-256, surah and juz index with search,
  reached from the Mushaf tab, with a saved reading position.
- Faster start-up and a repeatable performance scenario (`docs/PERFORMANCE.md`).
- Drafted font and layout permission requests (`docs/PERMISSION_REQUESTS.md`).

- Quran text logic: Tanzil Uthmani and Simple Clean bundled with checked SHA-256, parser with
  structure validation, verified loader off the main isolate, lookup by surah/ayah/page, and
  diacritic-free ayah search with ranking.

- Text re-downloaded with Tanzil's default options (pause marks, sajdah signs), basmala prefix
  separated without editing, and cross-checked against Quran.com: 6,236 of 6,236 identical.
- Quran search by surah name or number, by ayah reference, and by words without tashkeel, with
  an organised results screen.

- Mushaf tab is now the reader: right-to-left page turns, saved position, own bar with index
  (menu), search, and display options (text size, theme), immersive reading on tap, and golden
  tests for pages 1, 2, 42, and 604 in light and dark.

- Hizb and rub' shown on pages; ayah long-press actions (copy with reference, bookmark); bookmarks
  list; two-page spread on wide windows.

- Printed Mushaf: exact ayah selection on every edition (ayah markers on the Sakina pages, glyph database on
  Quran.com), a splash on the tapped ayah, pages spread over the screen, and offline packs downloaded in the
  background with a notification (`docs/QURAN_SOURCES.md`, section 12).

- Adhkar: data-driven collections (manifest + checked files), per-dhikr counter with light and firm
  haptics, evidence sheet, groups, prayer windows, daily reminders (`docs/ADHKAR_SOURCES.md`). Smart back
  (other tab → Mushaf → close warning), keyboard-aware `AppSheet`, new expanding Android tab bar.

## In progress

- Foundation migration: localization, typed routing, Riverpod, adaptive shell,
  and Liquid Glass integration assessment.

## Blocked

- Exact Mushaf renderer: matching QCF font/page-map source and redistribution
  terms are not yet verified.
- Image mode: image source, licence, format, and size are intentionally unknown.

## Measurements

- Baseline release size: pending first `appbundle --analyze-size` run.
- Coverage: pending foundation migration.
- Profile frame times: pending a device or simulator run.
- Firebase verification: `fvm flutter analyze` clean; `fvm flutter test` passed
  9 tests; iOS simulator and Android debug app bundle built with Firebase SDKs.
- Android build warning: `firebase_core`, `firebase_crashlytics`, and
  `mre_fields` transitively apply the legacy Kotlin Gradle Plugin. Track their
  releases before Flutter makes built-in Kotlin mandatory.
