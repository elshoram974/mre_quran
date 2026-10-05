# Decisions

## D-001: Use the existing project identity

- **Decision:** Keep `MRE Quran` and `net.mrecode.mreQuran`.
- **Alternatives:** Rename the application or recreate the project.
- **Reason:** The application already exists and the request did not provide a
  replacement identity.

## D-002: Use FVM Flutter 3.47.5

- **Decision:** Run project commands through `fvm flutter`.
- **Alternatives:** Use the globally selected Flutter 3.44.1.
- **Reason:** `.fvmrc` and `pubspec.yaml` require Flutter 3.47.5 / Dart 3.13.4.

## D-003: Adapt by constraints

- **Decision:** Use compact, medium, and expanded window widths instead of
  device detection.
- **Alternatives:** Branch by iPhone, iPad, Android foldable, or orientation.
- **Reason:** This preserves state through iPhone Duo and foldable resizing and
  also works in split view and desktop windows.

## D-004: Glass is chrome, never Quran content

- **Decision:** Limit translucent Liquid Glass surfaces to navigation, sheets,
  and controls.
- **Alternatives:** Blur the Mushaf page or use a full-screen glass effect.
- **Reason:** The reader needs stable contrast, lower GPU cost, and reverence.

## D-005: Firebase Crashlytics stays disabled until consent and configuration

- **Decision:** Do not initialise Crashlytics or analytics without a real
  Firebase configuration and explicit user consent.
- **Alternatives:** Add a placeholder configuration or collect automatically.
- **Reason:** This preserves the offline/private product promise and avoids
  invalid Firebase setup.

## D-006: Do not bundle QCF assets yet

- **Decision:** Wait for a verified KFGQPC font source and its redistribution
  terms before committing fonts or page maps.
- **Alternatives:** Repackage a third-party mirror or use a generic Arabic font.
- **Reason:** Exact Madinah layout and Quran integrity cannot be claimed without
  a verified matching source.

## D-007: iOS minimum deployment target is 16.0

- **Decision:** Raise the iOS target from 15.0 to 16.0.
- **Alternatives:** Remove `liquidify` or ship a separate iOS 15 fallback.
- **Reason:** The requested `liquidify` plugin declares iOS 16.0 as its minimum
  platform. iPhone Duo runs a newer system, so this keeps the requested native
  glass path available without conditional package loading.
