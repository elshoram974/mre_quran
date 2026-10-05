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

## In progress

- Foundation migration: localization, typed routing, Riverpod, adaptive shell,
  and Liquid Glass integration assessment.

## Blocked

- Exact Mushaf renderer: matching QCF font/page-map source and redistribution
  terms are not yet verified.
- Crashlytics activation: Firebase project configuration and reporting-consent
  decision are not available.
- Image mode: image source, licence, format, and size are intentionally unknown.

## Measurements

- Baseline release size: pending first `appbundle --analyze-size` run.
- Coverage: pending foundation migration.
- Profile frame times: pending a device or simulator run.
- Verification after glass migration: `fvm flutter analyze` clean; `fvm flutter
  test` passed 8 tests; iOS simulator and Android debug app bundle both built.
- Android build warning: `mre_fields` transitively includes `pasteboard`, which
  still applies the legacy Kotlin Gradle Plugin. Track it before the Flutter
  built-in Kotlin migration becomes mandatory.
